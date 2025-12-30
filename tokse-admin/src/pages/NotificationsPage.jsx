import { differenceInHours, format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { AlertTriangle, Bell, CheckCircle, Clock, Trash2 } from 'lucide-react';
import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';

export const NotificationsPage = () => {
  const [deletionRequests, setDeletionRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  
  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(5);

  useEffect(() => {
    fetchDeletionRequests();
    
    // Check for auto-deactivation every minute
    const interval = setInterval(checkAutoDeactivation, 60000);

    // Real-time subscription
    const channel = supabase
      .channel('deletion_requests')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'demandes_suppression' }, () => {
        fetchDeletionRequests();
      })
      .subscribe();

    return () => {
      clearInterval(interval);
      supabase.removeChannel(channel);
    };
  }, []);

  const fetchDeletionRequests = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('demandes_suppression')
        .select(`
          *,
          utilisateur:utilisateur_id(*)
        `)
        .eq('statut', 'en_attente')
        .order('created_at', { ascending: true });

      if (error) throw error;
      setDeletionRequests(data || []);
    } catch (error) {
      console.error('Error fetching deletion requests:', error);
    } finally {
      setLoading(false);
    }
  };

  const checkAutoDeactivation = async () => {
    try {
      const now = new Date();
      
      for (const request of deletionRequests) {
        const requestDate = new Date(request.created_at);
        const hoursPassed = differenceInHours(now, requestDate);
        
        if (hoursPassed >= 48 && request.statut === 'en_attente') {
          await processDeactivation(request.utilisateur_id, true);
        }
      }
    } catch (error) {
      console.error('Error checking auto-deactivation:', error);
    }
  };

  const processDeactivation = async (userId, isAuto = false) => {
    try {
      // Deactivate user
      const { error: updateError } = await supabase
        .from('utilisateurs')
        .update({ 
          est_actif: false,
          date_desactivation: new Date().toISOString()
        })
        .eq('id', userId);

      if (updateError) throw updateError;

      // Update deletion request status
      const { error: requestError } = await supabase
        .from('demandes_suppression')
        .update({ 
          statut: 'traitee',
          traite_par: isAuto ? 'systeme' : 'admin',
          date_traitement: new Date().toISOString()
        })
        .eq('utilisateur_id', userId)
        .eq('statut', 'en_attente');

      if (requestError) throw requestError;

      // Log activity
      const { data: { user: currentUser } } = await supabase.auth.getUser();
      await supabase.from('logs_activite').insert({
        type_action: 'desactivation_compte',
        autorite_id: currentUser?.id,
        utilisateur_cible_id: userId,
        details: {
          raison: 'Demande de suppression de compte',
          traitement: isAuto ? 'Automatique (48h écoulées)' : 'Manuel par admin',
          timestamp: new Date().toISOString(),
        },
      });

      fetchDeletionRequests();
      alert(isAuto ? 'Compte désactivé automatiquement' : 'Compte désactivé avec succès');
    } catch (error) {
      console.error('Error processing deactivation:', error);
      alert('Erreur lors de la désactivation du compte');
    }
  };

  const cancelDeletionRequest = async (requestId, userId) => {
    try {
      const { error } = await supabase
        .from('demandes_suppression')
        .update({ 
          statut: 'annulee',
          date_traitement: new Date().toISOString()
        })
        .eq('id', requestId);

      if (error) throw error;

      fetchDeletionRequests();
      alert('Demande de suppression annulée');
    } catch (error) {
      console.error('Error canceling deletion request:', error);
      alert('Erreur lors de l\'annulation');
    }
  };

  const getRemainingTime = (createdAt) => {
    const requestDate = new Date(createdAt);
    const now = new Date();
    const hoursPassed = differenceInHours(now, requestDate);
    const hoursRemaining = 48 - hoursPassed;
    
    if (hoursRemaining <= 0) {
      return { text: 'Délai expiré', color: 'text-red-600', urgent: true };
    } else if (hoursRemaining <= 6) {
      return { text: `${hoursRemaining}h restantes`, color: 'text-red-600', urgent: true };
    } else if (hoursRemaining <= 24) {
      return { text: `${hoursRemaining}h restantes`, color: 'text-orange-600', urgent: false };
    } else {
      return { text: `${hoursRemaining}h restantes`, color: 'text-blue-600', urgent: false };
    }
  };

  // Calcul pagination
  const totalPages = Math.ceil(deletionRequests.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentRequests = deletionRequests.slice(startIndex, endIndex);

  const goToPage = (page) => {
    setCurrentPage(Math.max(1, Math.min(page, totalPages)));
  };

  return (
    <div className="bg-gray-50 min-h-screen p-6">
      {/* Header */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 mb-8">
        <div className="flex items-center gap-4 p-6">
          <Bell className="w-10 h-10 text-blue-600" />
          <div className="flex-1">
            <h1 className="text-2xl font-bold text-gray-900">Notifications</h1>
            <p className="text-gray-600 text-sm mt-1">
              Demandes de suppression de compte en attente
            </p>
          </div>
        </div>
      </div>

      {/* Alert Banner */}
      {deletionRequests.length > 0 && (
        <div className="mb-6 bg-white rounded-lg shadow-sm border border-gray-200 p-4" style={{ borderLeft: '4px solid rgb(249, 115, 22)' }}>
          <div className="flex items-start gap-3">
            <AlertTriangle className="w-5 h-5 text-orange-600 flex-shrink-0 mt-0.5" />
            <div>
              <p className="font-semibold text-gray-900">
                {deletionRequests.length} demande(s) de suppression en attente
              </p>
              <p className="text-sm text-gray-600 mt-1">
                Les comptes seront automatiquement désactivés après 48h si aucune action n'est prise.
              </p>
            </div>
          </div>
        </div>
      )}

      {loading ? (
        <div className="flex items-center justify-center h-64 bg-white rounded-lg shadow-sm border border-gray-200">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
        </div>
      ) : deletionRequests.length === 0 ? (
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-12 text-center">
          <CheckCircle className="w-16 h-16 text-green-600 mx-auto mb-4" />
          <h3 className="text-xl font-bold text-gray-900 mb-2">
            Aucune demande en attente
          </h3>
          <p className="text-gray-600">
            Toutes les demandes de suppression ont été traitées.
          </p>
        </div>
      ) : (
        <>
          <div className="space-y-4">
            {currentRequests.map((request) => {
            const remainingTime = getRemainingTime(request.created_at);
            
            return (
              <div
                key={request.id}
                className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-all"
                style={{ borderLeft: `4px solid ${remainingTime.urgent ? 'rgb(239, 68, 68)' : 'rgb(59, 130, 246)'}` }}
              >
                <div className="flex items-start justify-between">
                  <div className="flex items-start gap-4 flex-1">
                    <div className={`p-3 rounded-lg ${remainingTime.urgent ? 'bg-red-100' : 'bg-blue-100'}`}>
                      <Trash2 className={`w-6 h-6 ${remainingTime.urgent ? 'text-red-600' : 'text-blue-600'}`} />
                    </div>
                    
                    <div className="flex-1">
                      <h3 className="text-lg font-bold text-gray-900">
                        {request.utilisateur?.prenom} {request.utilisateur?.nom}
                      </h3>
                      <p className="text-sm text-gray-600 mt-1">
                        <span className="font-medium">Email:</span> {request.utilisateur?.email}
                      </p>
                      <p className="text-sm text-gray-600">
                        <span className="font-medium">Téléphone:</span> {request.utilisateur?.numero_telephone}
                      </p>
                      
                      <div className="flex items-center gap-4 mt-4">
                        <div className="flex items-center gap-2 text-gray-600">
                          <Clock className="w-4 h-4" />
                          <span className="text-sm">
                            {format(new Date(request.created_at), 'dd MMM yyyy à HH:mm', { locale: fr })}
                          </span>
                        </div>
                      </div>
                      
                      {request.raison && (
                        <div className="mt-3 p-3 bg-gray-50 rounded-lg border border-gray-200">
                          <p className="text-sm text-gray-700">
                            <span className="font-semibold">Raison :</span> {request.raison}
                          </p>
                        </div>
                      )}
                    </div>
                  </div>
                  
                  <div className="text-right ml-4">
                    <div className={`inline-flex items-center gap-2 px-4 py-2 rounded-lg font-semibold ${
                      remainingTime.urgent ? 'bg-red-100 text-red-700' : 'bg-blue-100 text-blue-700'
                    }`}>
                      <Clock className="w-4 h-4" />
                      {remainingTime.text}
                    </div>
                    
                    <div className="flex gap-2 mt-4">
                      <button
                        onClick={() => processDeactivation(request.utilisateur_id, false)}
                        className="flex items-center gap-2 bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 transition-colors text-sm"
                      >
                        <Trash2 className="w-4 h-4" />
                        Désactiver
                      </button>
                      <button
                        onClick={() => cancelDeletionRequest(request.id, request.utilisateur_id)}
                        className="bg-gray-200 text-gray-700 px-4 py-2 rounded-lg hover:bg-gray-300 transition-colors text-sm"
                      >
                        Annuler
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
          </div>

          {/* Pagination */}
          {deletionRequests.length > 0 && (
            <div className="mt-6 bg-white rounded-lg shadow-sm border border-gray-200 p-4">
              <div className="flex items-center justify-between">
                {/* Info */}
                <div className="flex items-center gap-6">
                  <div className="text-sm">
                    <span className="text-blue-600 font-medium">{startIndex + 1}-{Math.min(endIndex, deletionRequests.length)}</span>
                    <span className="text-gray-500"> / </span>
                    <span className="text-blue-600 font-medium">{deletionRequests.length}</span>
                  </div>
                  
                  <div className="h-6 w-px bg-gray-300"></div>
                  
                  <div className="flex items-center gap-2">
                    <label className="text-sm text-gray-600 font-medium">Afficher:</label>
                    <select
                      value={itemsPerPage}
                      onChange={(e) => {
                        setItemsPerPage(Number(e.target.value));
                        setCurrentPage(1);
                      }}
                      className="px-3 py-1.5 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-blue-500 bg-white"
                    >
                      <option value={5}>5</option>
                      <option value={10}>10</option>
                      <option value={20}>20</option>
                      <option value={50}>50</option>
                    </select>
                  </div>
                </div>

                {/* Controls */}
                <div className="flex items-center gap-2">
                  <button 
                    onClick={() => goToPage(1)} 
                    disabled={currentPage === 1} 
                    className="px-3 py-2 text-sm bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed"
                  >
                    ««
                  </button>
                  
                  <button 
                    onClick={() => goToPage(currentPage - 1)} 
                    disabled={currentPage === 1} 
                    className="px-3 py-2 text-sm bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed"
                  >
                    ‹ Préc
                  </button>
                  
                  <div className="flex items-center gap-1">
                    {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => {
                      let page;
                      if (totalPages <= 5) {
                        page = i + 1;
                      } else if (currentPage <= 3) {
                        page = i + 1;
                      } else if (currentPage >= totalPages - 2) {
                        page = totalPages - 4 + i;
                      } else {
                        page = currentPage - 2 + i;
                      }
                      
                      const isActive = currentPage === page;
                      
                      return (
                        <button 
                          key={page} 
                          onClick={() => goToPage(page)} 
                          className={`min-w-[40px] px-3 py-2 text-sm rounded-lg transition-all ${
                            isActive ? 'bg-blue-600 text-white' : 'bg-white border border-gray-300 hover:bg-gray-50'
                          }`}
                        >
                          {page}
                        </button>
                      );
                    })}
                  </div>

                  <button 
                    onClick={() => goToPage(currentPage + 1)} 
                    disabled={currentPage === totalPages} 
                    className="px-3 py-2 text-sm bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed"
                  >
                    Suiv ›
                  </button>
                  
                  <button 
                    onClick={() => goToPage(totalPages)} 
                    disabled={currentPage === totalPages} 
                    className="px-3 py-2 text-sm bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed"
                  >
                    »»
                  </button>
                </div>
              </div>
              
              {/* Progress Bar */}
              <div className="mt-4">
                <div className="w-full bg-gray-200 rounded-full h-1.5">
                  <div 
                    className="bg-blue-600 h-1.5 rounded-full transition-all duration-300"
                    style={{ width: `${(currentPage / totalPages) * 100}%` }}
                  ></div>
                </div>
                <div className="flex justify-between mt-1">
                  <span className="text-xs text-gray-500">Page {currentPage}/{totalPages}</span>
                  <span className="text-xs text-gray-500">{Math.round((currentPage / totalPages) * 100)}%</span>
                </div>
              </div>
            </div>
          )}
        </>
      )}

      {/* Info Box */}
      <div className="mt-8 bg-white rounded-lg shadow-sm border border-gray-200 p-6" style={{ borderLeft: '4px solid rgb(59, 130, 246)' }}>
        <h3 className="font-bold text-gray-900 mb-3">ℹ️ Règles de suppression</h3>
        <ul className="space-y-2 text-sm text-gray-600">
          <li className="flex items-start gap-2">
            <span className="font-semibold text-blue-600">1.</span>
            <span>L'utilisateur clique sur "Supprimer mon compte" dans l'application</span>
          </li>
          <li className="flex items-start gap-2">
            <span className="font-semibold text-blue-600">2.</span>
            <span>Le compte est marqué comme "en attente de suppression"</span>
          </li>
          <li className="flex items-start gap-2">
            <span className="font-semibold text-blue-600">3.</span>
            <span>L'administrateur reçoit une notification (cette page)</span>
          </li>
          <li className="flex items-start gap-2">
            <span className="font-semibold text-blue-600">4.</span>
            <span>L'admin a 48h pour désactiver manuellement le compte</span>
          </li>
          <li className="flex items-start gap-2">
            <span className="font-semibold text-blue-600">5.</span>
            <span>Après 48h → désactivation automatique du compte</span>
          </li>
          <li className="flex items-start gap-2 mt-4 pt-4 border-t border-gray-200">
            <span className="font-semibold text-orange-600">⚠️</span>
            <span>Durant la période d'attente, l'utilisateur peut utiliser l'app mais ne peut ni modifier son profil ni créer de nouveaux signalements.</span>
          </li>
        </ul>
      </div>
    </div>
  );
};
