import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { BarChart3, Calendar, Download, FileText, TrendingUp } from 'lucide-react';
import { useEffect, useState } from 'react';
import * as XLSX from 'xlsx';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../lib/supabase';

export const AutoriteReportsPage = () => {
  const { user } = useAuth();
  const [loading, setLoading] = useState(false);
  const [stats, setStats] = useState(null);
  const [dateRange, setDateRange] = useState({
    startDate: format(new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), 'yyyy-MM-dd'),
    endDate: format(new Date(), 'yyyy-MM-dd'),
  });

  useEffect(() => {
    fetchStats();
  }, [dateRange, user]);

  const fetchStats = async () => {
    try {
      setLoading(true);

      // Récupérer les informations complètes de l'utilisateur depuis la base de données
      const { data: userData, error: userError } = await supabase
        .from('users')
        .select('id, nom, prenom, email, telephone, role')
        .eq('id', user?.id)
        .single();

      if (userError) {
        console.error('❌ [REPORTS] Error fetching user data:', userError);
      } else {
        console.log('📊 [REPORTS] User data from DB:', userData);
        // Fusionner les données user avec les données de la DB
        Object.assign(user, userData);
      }

      // Fonction pour mapper le role vers autorite_type
      const getAutoriteType = (user) => {
        if (!user) return null;
        if (user.autorite_type) return user.autorite_type;
        const roleMapping = {
          'police': 'police',
          'police_municipale': 'police',
          'hygiene': 'hygiene',
          'voirie': 'voirie',
          'environnement': 'environnement',
          'securite': 'securite',
          'mairie': 'mairie'
        };
        return roleMapping[user.role] || user.role;
      };

      const autoriteType = getAutoriteType(user);

      console.log('📊 [REPORTS] Fetching stats for period:', dateRange);
      console.log('📊 [REPORTS] User ID:', user?.id);

      // Signalements (tous les signalements pour cette autorité basé sur assigned_to)
      const { data: signalements, error: sigError } = await supabase
        .from('signalements')
        .select('*')
        .gte('created_at', new Date(dateRange.startDate).toISOString())
        .lte('created_at', new Date(dateRange.endDate).toISOString());

      console.log('📊 [REPORTS] Total signalements (filtered by period):', signalements?.length);

      if (sigError) throw sigError;

      // Mes prises en charge
      const { data: mesPrisesEnCharge, error: prError } = await supabase
        .from('signalements')
        .select('*')
        .eq('assigned_to', user?.id)
        .gte('created_at', new Date(dateRange.startDate).toISOString())
        .lte('created_at', new Date(dateRange.endDate).toISOString());

      console.log('📊 [REPORTS] Mes prises en charge (filtered by period):', mesPrisesEnCharge?.length);

      if (prError) throw prError;

      // Calculs
      const total = signalements?.length || 0;
      const traites = signalements?.filter((s) => s.etat === 'resolu').length || 0;
      const enCours = signalements?.filter((s) => s.etat === 'en_cours').length || 0;
      const enAttente = signalements?.filter((s) => s.etat === 'en_attente').length || 0;

      // Par catégorie
      const byCategorie = {};
      signalements?.forEach((sig) => {
        byCategorie[sig.categorie] = (byCategorie[sig.categorie] || 0) + 1;
      });

      // Temps de résolution moyen (basé sur resolved_at)
      const signalementsTraites = signalements?.filter((s) => s.etat === 'resolu' && s.resolved_at) || [];
      let tempsTotal = 0;
      signalementsTraites.forEach((s) => {
        const created = new Date(s.created_at);
        const resolved = new Date(s.resolved_at);
        tempsTotal += (resolved - created) / (1000 * 60 * 60); // en heures
      });
      const tempsResolutionMoyen = signalementsTraites.length > 0 ? tempsTotal / signalementsTraites.length : 0;

      // Mes statistiques personnelles
      const mesPrisesTotal = mesPrisesEnCharge?.length || 0;
      const mesPrisesResolues = mesPrisesEnCharge?.filter((s) => s.etat === 'resolu').length || 0;

      console.log('📊 [REPORTS] Stats calculées:', {
        total,
        traites,
        enCours,
        enAttente,
        mesPrisesTotal,
        mesPrisesResolues,
        tempsResolutionMoyen
      });

      setStats({
        signalements: {
          total,
          traites,
          enCours,
          enAttente,
          tauxResolution: total > 0 ? Math.round((traites / total) * 100) : 0,
          byCategorie,
        },
        mesStats: {
          total: mesPrisesTotal,
          resolus: mesPrisesResolues,
          tauxReussite: mesPrisesTotal > 0 ? Math.round((mesPrisesResolues / mesPrisesTotal) * 100) : 0,
        },
        tempsResolutionMoyen: Math.round(tempsResolutionMoyen),
        data: {
          signalements,
          mesPrisesEnCharge,
        },
      });
    } catch (error) {
      console.error('❌ [REPORTS] Error fetching stats:', error);
      console.error('❌ [REPORTS] Error details:', error.message, error.details);
    } finally {
      setLoading(false);
    }
  };

  const exportToPDF = () => {
    try {
      console.log('📄 [PDF] Starting PDF generation...');
      console.log('📄 [PDF] User object:', user);
      console.log('📄 [PDF] User metadata:', user?.user_metadata);
      console.log('📄 [PDF] Stats:', stats);
      
      if (!stats) {
        console.error('❌ [PDF] No stats available');
        alert('Aucune donnée à exporter. Veuillez attendre le chargement des statistiques.');
        return;
      }

      const doc = new jsPDF();
      const pageWidth = doc.internal.pageSize.width;
      const pageHeight = doc.internal.pageSize.height;

      // === EN-TETE AVEC BANDE BLEUE ===
      doc.setFillColor(26, 115, 232); // Bleu TOKSE
      doc.rect(0, 0, pageWidth, 40, 'F');
      
      doc.setTextColor(255, 255, 255);
      doc.setFontSize(24);
      doc.setFont('helvetica', 'bold');
      doc.text('RAPPORT D\'ACTIVITÉS - OPÉRATEUR', pageWidth / 2, 15, { align: 'center' });
      
      doc.setFontSize(12);
      doc.setFont('helvetica', 'normal');
      doc.text('Plateforme TOKSE - Système de gestion des signalements utilisateurs', pageWidth / 2, 25, { align: 'center' });
      doc.text('(Généré automatiquement par la plateforme)', pageWidth / 2, 32, { align: 'center' });

      doc.setTextColor(0, 0, 0);
      doc.setFontSize(11);
      doc.setFont('helvetica', 'normal');
      
      // Informations de l'autorité (GAUCHE)
      doc.setFont('helvetica', 'bold');
      doc.text('Informations de l\'autorité', 20, 50);
      doc.setFont('helvetica', 'normal');
      doc.text(`Nom : ${user?.nom || 'N/A'} ${user?.prenom || ''}`, 20, 57);
      doc.text(`Rôle : ${user?.role || user?.autorite_type || 'N/A'}`, 20, 64);
      doc.text(`Email : ${user?.email || 'N/A'}`, 20, 71);
      doc.text(`Téléphone : ${user?.telephone || user?.phone || 'Non renseigné'}`, 20, 78);
      
      // Informations du rapport (DROITE)
      const rightX = pageWidth - 20;
      doc.setFont('helvetica', 'bold');
      doc.text('Informations du rapport', rightX, 50, { align: 'right' });
      doc.setFont('helvetica', 'normal');
      doc.text(`Période du rapport : ${format(new Date(dateRange.startDate), 'dd/MM/yyyy', { locale: fr })} - ${format(new Date(dateRange.endDate), 'dd/MM/yyyy', { locale: fr })}`, rightX, 57, { align: 'right' });
      doc.text(`Généré le : ${format(new Date(), 'dd/MM/yyyy HH:mm', { locale: fr })}`, rightX, 64, { align: 'right' });

      // Statistiques globales
      doc.setFontSize(14);
      doc.setFont('helvetica', 'bold');
      doc.setTextColor(0, 0, 0);
      doc.text('Statistiques Globales', 20, 90);

      const statsData = [
        ['Total de signalements', stats.signalements.total],
        ['Signalements traités', stats.signalements.traites],
        ['Signalements en cours de traitement', stats.signalements.enCours],
        ['Signalements en attente', stats.signalements.enAttente],
        ['Taux de résolution', `${stats.signalements.tauxResolution} %`],
        ['Temps moyen de résolution', `${stats.tempsResolutionMoyen} h`],
        ['Mes prises en charge', stats.mesStats.total],
        ['Mes résolutions', stats.mesStats.resolus],
        ['Mon taux de réussite', `${stats.mesStats.tauxReussite} %`],
      ];

      autoTable(doc, {
        startY: 97,
        head: [['Indicateur', 'Valeur']],
        body: statsData,
        theme: 'grid',
        headStyles: { fillColor: [37, 99, 235], font: 'helvetica' },
        styles: { font: 'helvetica' },
      });

      // Mes interventions détaillées
      let finalY = doc.lastAutoTable.finalY + 15;
      doc.setFontSize(14);
      doc.setFont('helvetica', 'bold');
      doc.text('Mes Interventions en Détail', 20, finalY);

      const getEtatLabel = (etat) => {
        switch(etat) {
          case 'resolu': return 'Résolu';
          case 'en_cours': return 'En cours';
          case 'en_attente': return 'En attente';
          default: return etat || 'Inconnu';
        }
      };

      const interventionsData = stats.data.mesPrisesEnCharge.map((sig) => [
        sig.titre || 'Sans titre',
        sig.categorie,
        getEtatLabel(sig.etat),
        format(new Date(sig.created_at), 'dd/MM/yyyy'),
        sig.resolved_at ? format(new Date(sig.resolved_at), 'dd/MM/yyyy') : '-',
      ]);

      if (interventionsData.length > 0) {
        autoTable(doc, {
          startY: finalY + 7,
          head: [['Titre', 'Catégorie', 'État', 'Date de prise en charge', 'Date de résolution']],
          body: interventionsData,
          theme: 'grid',
          headStyles: { fillColor: [37, 99, 235], font: 'helvetica' },
          styles: { fontSize: 9, font: 'helvetica' },
          margin: { bottom: 30 },
        });
        finalY = doc.lastAutoTable.finalY + 15;
      } else {
        doc.setFontSize(10);
        doc.setFont('helvetica', 'italic');
        doc.text('Aucune intervention pour cette période', 20, finalY + 10);
        finalY = finalY + 30;
      }

      // Par catégorie
      doc.setFontSize(14);
      doc.setFont('helvetica', 'bold');
      doc.text('Répartition par Catégorie', 20, finalY);

      const categorieData = Object.entries(stats.signalements.byCategorie).map(([cat, count]) => [cat, count]);

      autoTable(doc, {
        startY: finalY + 7,
        head: [['Catégorie', 'Nombre']],
        body: categorieData,
        theme: 'grid',
        headStyles: { fillColor: [37, 99, 235], font: 'helvetica' },
        styles: { font: 'helvetica' },
        margin: { bottom: 35 },
      });

      // === PIED DE PAGE AVEC BANDE BLEUE ===
      const pageCount = doc.internal.getNumberOfPages();
      for (let i = 1; i <= pageCount; i++) {
        doc.setPage(i);
        
        // Bande bleue en bas
        doc.setFillColor(26, 115, 232); // Bleu TOKSE
        doc.rect(0, pageHeight - 20, pageWidth, 20, 'F');
        
        // Texte en blanc
        doc.setTextColor(255, 255, 255);
        doc.setFontSize(10);
        doc.setFont('helvetica', 'normal');
        doc.text(
          `(c) ${new Date().getFullYear()} TOKSE - Crafted And Developed By AMIR TECH`,
          pageWidth / 2,
          pageHeight - 10,
          { align: 'center' }
        );
      }

      // Sauvegarder
      const filename = `rapport_activite_${format(new Date(), 'yyyy-MM-dd_HHmmss')}.pdf`;
      console.log('✅ [PDF] Saving PDF:', filename);
      doc.save(filename);
      console.log('✅ [PDF] PDF generated successfully');
    } catch (error) {
      console.error('❌ [PDF] Error generating PDF:', error);
      alert(`Erreur lors de la génération du PDF: ${error.message}`);
    }
  };

  const exportToExcel = () => {
    try {
      console.log('📊 [EXCEL] Starting Excel generation...');
      
      if (!stats) {
        console.error('❌ [EXCEL] No stats available');
        alert('Aucune donnée à exporter. Veuillez attendre le chargement des statistiques.');
        return;
      }

      // Feuille 1: Résumé
      const resumeData = [
        ['RAPPORT D\'ACTIVITÉ'],
        [],
        ['Autorité', user?.role || user?.autorite_type || 'N/A'],
        ['Période', `${format(new Date(dateRange.startDate), 'dd/MM/yyyy')} - ${format(new Date(dateRange.endDate), 'dd/MM/yyyy')}`],
        ['Généré le', format(new Date(), 'dd/MM/yyyy HH:mm')],
        [],
        ['STATISTIQUES GLOBALES'],
        ['Total signalements', stats.signalements.total],
        ['Signalements traités', stats.signalements.traites],
        ['Signalements en cours', stats.signalements.enCours],
        ['Signalements en attente', stats.signalements.enAttente],
        ['Taux de résolution', `${stats.signalements.tauxResolution}%`],
        ['Temps moyen de résolution', `${stats.tempsResolutionMoyen}h`],
        ['Mes prises en charge', stats.mesStats.total],
        ['Mes résolutions', stats.mesStats.resolus],
        ['Mon taux de réussite', `${stats.mesStats.tauxReussite}%`],
      ];

    // Feuille 2: Signalements détaillés
    const signalementsData = [
      ['ID', 'Titre', 'Catégorie', 'État', 'Adresse', 'Date création', 'Date résolution'],
      ...stats.data.signalements.map((sig) => [
        sig.id,
        sig.titre || 'Sans titre',
        sig.categorie,
        sig.etat,
        sig.adresse || 'N/A',
        format(new Date(sig.created_at), 'dd/MM/yyyy HH:mm'),
        sig.resolved_at ? format(new Date(sig.resolved_at), 'dd/MM/yyyy HH:mm') : 'N/A',
      ]),
    ];

    // Feuille 3: Mes prises en charge
    const mesPrisesData = [
      ['ID', 'Titre', 'Catégorie', 'État', 'Adresse', 'Date prise en charge', 'Date résolution'],
      ...stats.data.mesPrisesEnCharge.map((sig) => [
        sig.id,
        sig.titre || 'Sans titre',
        sig.categorie,
        sig.etat,
        sig.adresse || 'N/A',
        format(new Date(sig.created_at), 'dd/MM/yyyy HH:mm'),
        sig.resolved_at ? format(new Date(sig.resolved_at), 'dd/MM/yyyy HH:mm') : 'N/A',
      ]),
    ];

    // Créer le workbook
      const wb = XLSX.utils.book_new();
      const wsResume = XLSX.utils.aoa_to_sheet(resumeData);
      const wsSignalements = XLSX.utils.aoa_to_sheet(signalementsData);
      const wsMesPrises = XLSX.utils.aoa_to_sheet(mesPrisesData);

      XLSX.utils.book_append_sheet(wb, wsResume, 'Résumé');
      XLSX.utils.book_append_sheet(wb, wsSignalements, 'Signalements');
      XLSX.utils.book_append_sheet(wb, wsMesPrises, 'Mes Prises en Charge');

      // Sauvegarder
      const filename = `rapport_activite_${format(new Date(), 'yyyy-MM-dd_HHmmss')}.xlsx`;
      console.log('✅ [EXCEL] Saving Excel:', filename);
      XLSX.writeFile(wb, filename);
      console.log('✅ [EXCEL] Excel generated successfully');
    } catch (error) {
      console.error('❌ [EXCEL] Error generating Excel:', error);
      alert(`Erreur lors de la génération du fichier Excel: ${error.message}`);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64 bg-gray-50">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div>
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Rapports et Statistiques</h1>
        <p className="text-gray-600 mt-2">Génération de rapports détaillés sur l'activité et les zones couvertes</p>
      </div>

      {/* Sélection période */}
      <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <Calendar className="w-5 h-5 text-gray-600" />
            <h3 className="font-semibold text-gray-900">Période d'analyse</h3>
          </div>
          <div className="flex gap-3">
            <button
              onClick={exportToPDF}
              disabled={!stats}
              className="flex items-center gap-2 bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <Download className="w-4 h-4" />
              Générer rapport PDF
            </button>
            <button
              onClick={exportToExcel}
              disabled={!stats}
              className="flex items-center gap-2 bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <Download className="w-4 h-4" />
              Générer rapport Excel
            </button>
          </div>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Date début</label>
            <input
              type="date"
              value={dateRange.startDate}
              onChange={(e) => setDateRange({ ...dateRange, startDate: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Date fin</label>
            <input
              type="date"
              value={dateRange.endDate}
              onChange={(e) => setDateRange({ ...dateRange, endDate: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>
      </div>

      {stats && (
        <>
          {/* Stats Cards */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
            <div className="bg-white p-6 rounded-xl shadow-sm border-l-4 border-blue-500">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Total signalements</p>
                  <p className="text-3xl font-bold text-gray-900 mt-2">{stats.signalements.total}</p>
                </div>
                <FileText className="w-12 h-12 text-blue-500 opacity-20" />
              </div>
            </div>
            <div className="bg-white p-6 rounded-xl shadow-sm border-l-4 border-green-500">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Taux de résolution</p>
                  <p className="text-3xl font-bold text-gray-900 mt-2">{stats.signalements.tauxResolution}%</p>
                </div>
                <TrendingUp className="w-12 h-12 text-green-500 opacity-20" />
              </div>
            </div>
            <div className="bg-white p-6 rounded-xl shadow-sm border-l-4 border-purple-500">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Temps moyen résolution</p>
                  <p className="text-3xl font-bold text-gray-900 mt-2">{stats.tempsResolutionMoyen}h</p>
                </div>
                <BarChart3 className="w-12 h-12 text-purple-500 opacity-20" />
              </div>
            </div>
            <div className="bg-white p-6 rounded-xl shadow-sm border-l-4 border-orange-500">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Mes prises en charge</p>
                  <p className="text-3xl font-bold text-gray-900 mt-2">{stats.mesStats.total}</p>
                </div>
                <BarChart3 className="w-12 h-12 text-orange-500 opacity-20" />
              </div>
            </div>
          </div>

          {/* Répartition */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
            {/* Par état */}
            <div className="bg-white rounded-xl shadow-sm p-6">
              <h3 className="text-lg font-bold text-gray-900 mb-4">Répartition par état</h3>
              <div className="space-y-3">
                <div className="flex items-center justify-between p-3 bg-green-50 rounded-lg">
                  <span className="text-sm font-medium text-gray-700">Traités</span>
                  <span className="text-lg font-bold text-green-600">{stats.signalements.traites}</span>
                </div>
                <div className="flex items-center justify-between p-3 bg-blue-50 rounded-lg">
                  <span className="text-sm font-medium text-gray-700">En cours</span>
                  <span className="text-lg font-bold text-blue-600">{stats.signalements.enCours}</span>
                </div>
                <div className="flex items-center justify-between p-3 bg-yellow-50 rounded-lg">
                  <span className="text-sm font-medium text-gray-700">En attente</span>
                  <span className="text-lg font-bold text-yellow-600">{stats.signalements.enAttente}</span>
                </div>
              </div>
            </div>

            {/* Par catégorie */}
            <div className="bg-white rounded-xl shadow-sm p-6">
              <h3 className="text-lg font-bold text-gray-900 mb-4">Répartition par catégorie</h3>
              <div className="space-y-2">
                {Object.entries(stats.signalements.byCategorie).map(([cat, count]) => (
                  <div key={cat} className="flex items-center justify-between p-2 hover:bg-gray-50 rounded">
                    <span className="text-sm text-gray-700 capitalize">{cat}</span>
                    <span className="font-semibold text-gray-900">{count}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Mes statistiques personnelles */}
          <div className="bg-white rounded-xl shadow-sm p-6">
            <h3 className="text-lg font-bold text-gray-900 mb-4">Mes Statistiques Personnelles</h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="p-4 bg-purple-50 rounded-lg">
                <p className="text-sm text-gray-600">Mes prises en charge</p>
                <p className="text-2xl font-bold text-purple-600 mt-1">{stats.mesStats.total}</p>
              </div>
              <div className="p-4 bg-green-50 rounded-lg">
                <p className="text-sm text-gray-600">Signalements résolus</p>
                <p className="text-2xl font-bold text-green-600 mt-1">{stats.mesStats.resolus}</p>
              </div>
              <div className="p-4 bg-blue-50 rounded-lg">
                <p className="text-sm text-gray-600">Taux de réussite</p>
                <p className="text-2xl font-bold text-blue-600 mt-1">{stats.mesStats.tauxReussite}%</p>
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  );
};
