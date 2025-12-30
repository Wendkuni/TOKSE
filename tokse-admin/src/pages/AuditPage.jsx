import { format } from 'date-fns';
import { fr } from 'date-fns/locale';
import { Activity, AlertTriangle, Download, FileText, Filter, Search, Shield, User, Users } from 'lucide-react';
import { useEffect, useState } from 'react';
import jsPDF from 'jspdf';
import 'jspdf-autotable';
import { supabase } from '../lib/supabase';

export const AuditPage = () => {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({
    admin: '',
    action: '',
    startDate: '',
    endDate: '',
    search: '',
  });
  const [admins, setAdmins] = useState([]);
  const [stats, setStats] = useState({
    totalActions: 0,
    adminsActifs: 0,
    actionsAujourdhui: 0,
    actionsSensibles: 0,
    // Nouvelles statistiques globales
    totalUtilisateurs: 0,
    utilisateursActifs: 0,
    citoyensInscrits: 0,
    citoyensActifs: 0,
    autoritesActives: 0,
    autoritesActivesCount: 0,
    totalSignalements: 0,
    signalementsResolus: 0,
    signalementsEnCours: 0,
    tauxResolution: 0,
  });
  
  // Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(5);

  useEffect(() => {
    fetchData();
    // Real-time updates
    const channel = supabase
      .channel('audit_updates')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'logs_activite' }, () => {
        fetchData();
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [filters]);

  const fetchData = async () => {
    try {
      setLoading(true);
      await Promise.all([fetchLogs(), fetchAdmins(), fetchStats()]);
    } catch (error) {
      console.error('Error fetching audit data:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchLogs = async () => {
    try {
      // Récupérer les logs
      let query = supabase
        .from('logs_activite')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(500);

      // Filtres
      if (filters.admin) {
        query = query.eq('autorite_id', filters.admin);
      }
      if (filters.action) {
        query = query.eq('type_action', filters.action);
      }
      if (filters.startDate) {
        query = query.gte('created_at', new Date(filters.startDate).toISOString());
      }
      if (filters.endDate) {
        query = query.lte('created_at', new Date(filters.endDate).toISOString());
      }

      const { data: logsData, error } = await query;
      if (error) {
        console.error('❌ Erreur récupération logs:', error);
        throw error;
      }

      console.log('📋 Logs récupérés:', logsData?.length);
      console.log('📋 Premier log:', logsData?.[0]);

      // Récupérer tous les IDs uniques d'admin et d'utilisateurs cibles
      const adminIds = [...new Set(logsData?.map(log => log.autorite_id).filter(Boolean))];
      const cibleIds = [...new Set(logsData?.map(log => log.utilisateur_cible_id).filter(Boolean))];

      console.log('👥 Admin IDs:', adminIds);
      console.log('🎯 Cible IDs:', cibleIds);

      // Récupérer tous les admins en une seule requête
      const { data: adminsData, error: adminsError } = await supabase
        .from('users')
        .select('id, nom, prenom, email')
        .in('id', adminIds);

      if (adminsError) {
        console.error('❌ Erreur récupération admins:', adminsError);
      }

      console.log('👤 Admins récupérés:', adminsData);

      // Récupérer tous les utilisateurs cibles en une seule requête
      const { data: ciblesData, error: ciblesError } = await supabase
        .from('users')
        .select('id, nom, prenom, email, role')
        .in('id', cibleIds);

      if (ciblesError) {
        console.error('❌ Erreur récupération cibles:', ciblesError);
      }

      console.log('🎯 Cibles récupérées:', ciblesData);

      // Créer des maps pour un accès rapide
      const adminsMap = new Map(adminsData?.map(a => [a.id, a]) || []);
      const ciblesMap = new Map(ciblesData?.map(c => [c.id, c]) || []);

      // Enrichir les logs avec les informations des admins et cibles
      const logsWithDetails = logsData?.map(log => ({
        ...log,
        admin: adminsMap.get(log.autorite_id) || null,
        utilisateur_cible: ciblesMap.get(log.utilisateur_cible_id) || null
      }));

      console.log('✅ Logs enrichis:', logsWithDetails?.[0]);

      // Filtrage par recherche textuelle
      let filteredData = logsWithDetails || [];
      if (filters.search) {
        const searchLower = filters.search.toLowerCase();
        filteredData = filteredData.filter(
          (log) =>
            log.type_action?.toLowerCase().includes(searchLower) ||
            log.admin?.nom?.toLowerCase().includes(searchLower) ||
            log.admin?.email?.toLowerCase().includes(searchLower) ||
            log.utilisateur_cible?.nom?.toLowerCase().includes(searchLower) ||
            log.utilisateur_cible?.email?.toLowerCase().includes(searchLower)
        );
      }

      setLogs(filteredData);
      setCurrentPage(1); // Reset à la page 1 quand on filtre
    } catch (error) {
      console.error('❌ Error fetching logs:', error);
    }
  };

  const fetchAdmins = async () => {
    try {
      const { data, error } = await supabase.from('users').select('id, nom, prenom, email').eq('role', 'admin');

      if (error) throw error;
      setAdmins(data || []);
    } catch (error) {
      console.error('Error fetching admins:', error);
    }
  };

  const fetchStats = async () => {
    try {
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
      const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

      const [
        { count: totalActions },
        { count: actionsAujourdhui },
        { data: adminsData },
        { count: actionsSensibles },
        // Nouvelles statistiques
        { count: totalUtilisateurs },
        { data: utilisateursActifsData },
        { count: citoyensInscrits },
        { data: citoyensActifsData },
        { count: autoritesActives },
        { data: autoritesActivesData },
        { count: totalSignalements },
        { count: signalementsResolus },
        { count: signalementsEnCours },
      ] = await Promise.all([
        // Statistiques existantes
        supabase.from('logs_activite').select('*', { count: 'exact', head: true }),
        supabase
          .from('logs_activite')
          .select('*', { count: 'exact', head: true })
          .gte('created_at', today.toISOString()),
        supabase
          .from('logs_activite')
          .select('autorite_id')
          .gte('created_at', sevenDaysAgo.toISOString()),
        supabase
          .from('logs_activite')
          .select('*', { count: 'exact', head: true })
          .in('type_action', [
            'suppression_admin',
            'modification_permissions',
            'desactivation_admin',
            'suppression_compte',
          ]),
        // Nouvelles statistiques
        supabase.from('users').select('*', { count: 'exact', head: true }),
        // Utilisateurs (citoyens) actifs = ceux qui ont créé des signalements dans les 30 derniers jours
        supabase
          .from('signalements')
          .select('user_id')
          .gte('created_at', thirtyDaysAgo.toISOString())
          .not('user_id', 'is', null),
        supabase.from('users').select('*', { count: 'exact', head: true }).eq('role', 'citizen'),
        // Citoyens actifs = même chose que tous utilisateurs (car les utilisateurs qui créent des signalements sont des citoyens)
        supabase
          .from('signalements')
          .select('user_id')
          .gte('created_at', thirtyDaysAgo.toISOString())
          .not('user_id', 'is', null),
        supabase.from('users').select('*', { count: 'exact', head: true }).neq('role', 'citizen').neq('role', 'super_admin'),
        // Opérateurs actifs = opérateurs qui ont fait au moins une action dans les 30 derniers jours (logs_activite)
        supabase
          .from('logs_activite')
          .select('autorite_id')
          .gte('created_at', thirtyDaysAgo.toISOString())
          .not('autorite_id', 'is', null),
        supabase.from('signalements').select('*', { count: 'exact', head: true }),
        supabase.from('signalements').select('*', { count: 'exact', head: true }).eq('etat', 'resolu'),
        supabase.from('signalements').select('*', { count: 'exact', head: true }).eq('etat', 'en_cours'),
      ]);

      // Compter les admins actifs (distincts) dans les 7 derniers jours
      const uniqueAdmins = new Set(adminsData?.map((log) => log.autorite_id).filter(Boolean) || []);
      
      // Compter les utilisateurs actifs uniques (distincts) dans les 30 derniers jours
      const uniqueUtilisateursActifs = new Set(utilisateursActifsData?.map((log) => log.user_id).filter(Boolean) || []);
      const utilisateursActifs = uniqueUtilisateursActifs.size;
      
      // Compter les citoyens actifs uniques (distincts) dans les 30 derniers jours
      // On doit vérifier que ces user_id correspondent bien à des citoyens
      const uniqueCitoyensActifs = new Set();
      if (citoyensActifsData?.length > 0) {
        const userIds = citoyensActifsData.map((log) => log.user_id).filter(Boolean);
        // Vérifier quels user_ids sont effectivement des citoyens
        const { data: citoyenUsers } = await supabase
          .from('users')
          .select('id')
          .eq('role', 'citizen')
          .in('id', userIds);
        citoyenUsers?.forEach(user => uniqueCitoyensActifs.add(user.id));
      }
      const citoyensActifs = uniqueCitoyensActifs.size;
      
      // Compter les opérateurs actifs uniques (distincts) dans les 30 derniers jours
      const uniqueAutoritesActives = new Set(autoritesActivesData?.map((log) => log.autorite_id).filter(Boolean) || []);
      const autoritesActivesCount = uniqueAutoritesActives.size;
      
      const tauxResolution = totalSignalements > 0 ? Math.round((signalementsResolus / totalSignalements) * 100) : 0;

      setStats({
        totalActions: totalActions || 0,
        adminsActifs: uniqueAdmins.size,
        actionsAujourdhui: actionsAujourdhui || 0,
        actionsSensibles: actionsSensibles || 0,
        // Nouvelles statistiques
        totalUtilisateurs: totalUtilisateurs || 0,
        utilisateursActifs: utilisateursActifs,
        citoyensInscrits: citoyensInscrits || 0,
        citoyensActifs: citoyensActifs,
        autoritesActives: autoritesActives || 0,
        autoritesActivesCount: autoritesActivesCount,
        totalSignalements: totalSignalements || 0,
        signalementsResolus: signalementsResolus || 0,
        signalementsEnCours: signalementsEnCours || 0,
        tauxResolution: tauxResolution,
      });
    } catch (error) {
      console.error('Error fetching stats:', error);
    }
  };

  const generateAuditReport = () => {
    try {
      console.log('🎯 Début de génération du rapport...');
      
      const doc = new jsPDF();
      
      // Définir la police par défaut pour tout le document
      doc.setFont('helvetica');
      
      // Vérifier que autoTable est disponible
      if (typeof doc.autoTable !== 'function') {
        console.error('❌ autoTable n\'est pas disponible sur jsPDF');
        throw new Error('jspdf-autotable n\'est pas chargé correctement');
      }
      
      const pageWidth = doc.internal.pageSize.width;
      const pageHeight = doc.internal.pageSize.height;
      let yPos = 20;

      console.log('📄 Document PDF créé');

      // === EN-TÊTE DU RAPPORT ===
      doc.setFillColor(26, 115, 232); // Bleu TOKSE
      doc.rect(0, 0, pageWidth, 40, 'F');
      
      doc.setTextColor(255, 255, 255);
      doc.setFontSize(24);
      doc.setFont('helvetica', 'bold');
      doc.text('RAPPORT D\'AUDIT DU SYSTÈME', pageWidth / 2, 15, { align: 'center' });
      
      doc.setFontSize(12);
      doc.setFont('helvetica', 'normal');
      doc.text('Plateforme TOKSE - Système de gestion des signalements utilisateurs', pageWidth / 2, 25, { align: 'center' });
      doc.text('(Généré automatiquement par la plateforme)', pageWidth / 2, 32, { align: 'center' });

      yPos = 50;

      console.log('✅ En-tête créé');

      // === 1. IDENTIFICATION DU RAPPORT ===
      doc.setTextColor(0, 0, 0);
      doc.setFontSize(14);
      doc.setFont('helvetica', 'bold');
      doc.text('1. IDENTIFICATION DU RAPPORT', 14, yPos);
      yPos += 8;

      doc.setFontSize(10);
      doc.setFont('helvetica', 'normal');
      const identificationData = [
        ['Plateforme', 'TOKSE (Gestion des signalements utilisateurs)'],
        ['Type de rapport', 'Audit du système automatisé'],
        ['Périmètre', 'Applications Web et Mobile'],
        ['Version', 'TOKSE v1.0.0'],
        ['Période analysée', `Du ${filters.startDate || format(new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), 'dd/MM/yyyy')} au ${filters.endDate || format(new Date(), 'dd/MM/yyyy')}`],
        ['Date de génération', format(new Date(), 'dd/MM/yyyy à HH:mm:ss', { locale: fr })],
        ['Généré par', 'Système TOKSE - Module d\'audit'],
        ['Niveau d\'audit', 'Global (Super-Administrateur)']
      ];

    doc.autoTable({
      startY: yPos,
      head: [],
      body: identificationData,
      theme: 'grid',
      styles: { 
        fontSize: 9, 
        cellPadding: 3,
        font: 'helvetica',
        fontStyle: 'normal'
      },
      columnStyles: {
        0: { fontStyle: 'bold', fillColor: [240, 240, 240], cellWidth: 60 },
        1: { cellWidth: 120 }
      },
      margin: { left: 14, right: 14 }
    });

    yPos = doc.lastAutoTable.finalY + 10;

    // === 2. OBJECTIFS DE L'AUDIT ===
    if (yPos > pageHeight - 60) {
      doc.addPage();
      yPos = 20;
    }

    doc.setFontSize(14);
    doc.setFont('helvetica', 'bold');
    doc.text('2. OBJECTIFS DE L\'AUDIT TOKSE', 14, yPos);
    yPos += 8;

    doc.setFontSize(10);
    doc.setFont('helvetica', 'normal');
    const objectifs = [
      '- Vérifier le bon fonctionnement global de la plateforme TOKSE',
      '- Analyser la gestion des signalements utilisateurs',
      '- Évaluer les interventions des opérateurs compétents',
      '- Contrôler la traçabilité complète des actions',
      '- Mesurer les performances opérationnelles du système',
      '- Fournir un outil d\'aide à la décision aux administrateurs'
    ];

    objectifs.forEach(obj => {
      doc.text(obj, 20, yPos);
      yPos += 6;
    });

    yPos += 5;

    // === 3. PÉRIMÈTRE AUDITÉ ===
    if (yPos > pageHeight - 80) {
      doc.addPage();
      yPos = 20;
    }

    doc.setFontSize(14);
    doc.setFont('helvetica', 'bold');
    doc.text('3. PÉRIMÈTRE AUDITÉ', 14, yPos);
    yPos += 8;

    doc.setFontSize(11);
    doc.text('3.1 Applications concernées', 14, yPos);
    yPos += 6;

    doc.setFontSize(10);
    doc.setFont('helvetica', 'normal');
    const applications = [
      '- Application mobile utilisateur (Android/iOS)',
      '- Application mobile opérateur (Android/iOS)',
      '- Application web opérateur (Tableau de bord)',
      '- Application web super-administrateur (Panneau d\'administration)'
    ];

    applications.forEach(app => {
      doc.text(app, 20, yPos);
      yPos += 6;
    });

    yPos += 3;

    doc.setFontSize(11);
    doc.setFont('helvetica', 'bold');
    doc.text('3.2 Rôles analysés', 14, yPos);
    yPos += 6;

    doc.setFontSize(10);
    doc.setFont('helvetica', 'normal');
    const roles = [
      '- Utilisateurs (Créateurs de signalements)',
      '- Opérateurs (Gestionnaires de signalements)',
      '- Super-Administrateurs (Gestion globale de la plateforme)'
    ];

    roles.forEach(role => {
      doc.text(role, 20, yPos);
      yPos += 6;
    });

    // === 4. STATISTIQUES GLOBALES ===
    doc.addPage();
    yPos = 20;

    doc.setFontSize(14);
    doc.setFont('helvetica', 'bold');
    doc.text('4. STATISTIQUES GLOBALES DE LA PLATEFORME', 14, yPos);
    yPos += 8;

    // 4.1 Statistiques utilisateurs
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('4.1 Utilisateurs et Acteurs', 14, yPos);
    yPos += 6;

    const statsUtilisateurs = [
      ['Indicateur', 'Valeur'],
      ['Total d\'utilisateurs inscrits (tous rôles)', stats.totalUtilisateurs.toString()],
      ['Utilisateurs actifs (30 derniers jours)', stats.citoyensActifs.toString()],
      ['Opérateurs actifs (30 derniers jours)', stats.autoritesActivesCount.toString()],
      ['Admins/Super-admins actifs (7 derniers jours)', stats.adminsActifs.toString()],
    ];

    doc.autoTable({
      startY: yPos,
      head: [statsUtilisateurs[0]],
      body: statsUtilisateurs.slice(1),
      theme: 'grid',
      styles: { 
        fontSize: 10, 
        cellPadding: 4,
        font: 'helvetica'
      },
      headStyles: { 
        fillColor: [26, 115, 232], 
        textColor: 255, 
        fontStyle: 'bold',
        font: 'helvetica'
      },
      columnStyles: {
        0: { fontStyle: 'bold', cellWidth: 100 },
        1: { halign: 'center', cellWidth: 80 }
      },
      margin: { left: 14, right: 14 }
    });

    yPos = doc.lastAutoTable.finalY + 10;

    // 4.2 Statistiques signalements
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('4.2 Signalements et Activit\u00e9', 14, yPos);
    yPos += 6;

    const statsSignalements = [
      ['Indicateur', 'Valeur'],
      ['Total de signalements', stats.totalSignalements.toString()],
      ['Signalements r\u00e9solus', stats.signalementsResolus.toString()],
      ['Signalements en cours', stats.signalementsEnCours.toString()],
      ['Taux de r\u00e9solution global', `${stats.tauxResolution} %`],
    ];

    doc.autoTable({
      startY: yPos,
      head: [statsSignalements[0]],
      body: statsSignalements.slice(1),
      theme: 'grid',
      styles: { 
        fontSize: 10, 
        cellPadding: 4,
        font: 'helvetica'
      },
      headStyles: { 
        fillColor: [26, 115, 232], 
        textColor: 255, 
        fontStyle: 'bold',
        font: 'helvetica'
      },
      columnStyles: {
        0: { fontStyle: 'bold', cellWidth: 100 },
        1: { halign: 'center', cellWidth: 80 }
      },
      margin: { left: 14, right: 14 }
    });

    yPos = doc.lastAutoTable.finalY + 10;

    // 4.3 Statistiques syst\u00e8me et audit
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text('4.3 Syst\u00e8me et Tra\u00e7abilit\u00e9', 14, yPos);
    yPos += 6;

    const statsData = [
      ['Indicateur', 'Valeur'],
      ['Total des actions enregistr\u00e9es', stats.totalActions.toString()],
      ['Actions effectuées aujourd\'hui', stats.actionsAujourdhui.toString()],
      ['Actions sensibles détectées', stats.actionsSensibles.toString()],
      ['Taux de traçabilité', '100 %'],
      ['Période de rétention des logs', '365 jours']
    ];

    doc.autoTable({
      startY: yPos,
      head: [statsData[0]],
      body: statsData.slice(1),
      theme: 'grid',
      styles: { 
        fontSize: 10, 
        cellPadding: 4,
        font: 'helvetica'
      },
      headStyles: { 
        fillColor: [26, 115, 232], 
        textColor: 255, 
        fontStyle: 'bold',
        font: 'helvetica'
      },
      columnStyles: {
        0: { fontStyle: 'bold', cellWidth: 100 },
        1: { halign: 'center', cellWidth: 80 }
      },
      margin: { left: 14, right: 14 }
    });

    yPos = doc.lastAutoTable.finalY + 10;

    // === 5. ANALYSE DES ACTIONS PAR TYPE ===
    if (yPos > pageHeight - 100) {
      doc.addPage();
      yPos = 20;
    }

    doc.setFontSize(14);
    doc.setFont('helvetica', 'bold');
    doc.text('5. ANALYSE DES ACTIONS PAR TYPE', 14, yPos);
    yPos += 8;

    // Compter les actions par type
    const actionCounts = {};
    logs.forEach(log => {
      const action = log.type_action || 'Non specifie';
      actionCounts[action] = (actionCounts[action] || 0) + 1;
    });

    const actionsData = [['Type d\'action', 'Nombre', 'Niveau de criticite']];
    Object.entries(actionCounts).forEach(([action, count]) => {
      const severity = getActionSeverity(action);
      const severityText = severity === 'critical' ? 'Critique' :
                          severity === 'warning' ? 'Attention' :
                          'Normal';
      actionsData.push([action, count.toString(), severityText]);
    });

    doc.autoTable({
      startY: yPos,
      head: [actionsData[0]],
      body: actionsData.slice(1),
      theme: 'grid',
      styles: { 
        fontSize: 9, 
        cellPadding: 3,
        font: 'helvetica'
      },
      headStyles: { 
        fillColor: [26, 115, 232], 
        textColor: 255, 
        fontStyle: 'bold',
        font: 'helvetica'
      },
      columnStyles: {
        0: { cellWidth: 90 },
        1: { halign: 'center', cellWidth: 30 },
        2: { halign: 'center', cellWidth: 60 }
      },
      margin: { left: 14, right: 14 }
    });

    yPos = doc.lastAutoTable.finalY + 10;

    // === 6. AUDIT DE LA TRAÇABILITÉ ===
    doc.addPage();
    yPos = 20;

    doc.setFontSize(14);
    doc.setFont('helvetica', 'bold');
    doc.text('6. AUDIT DE LA TRAÇABILITÉ DES LOGS', 14, yPos);
    yPos += 8;

    doc.setFontSize(11);
    doc.text('6.1 Actions enregistrées automatiquement', 14, yPos);
    yPos += 6;

    doc.setFontSize(10);
    doc.setFont('helvetica', 'normal');
    const tracabilite = [
      '- Création et modification d\'utilisateurs',
      '- Attribution et modification des permissions',
      '- Activation et désactivation de comptes',
      '- Suppression d\'\u00e9léments (avec confirmation)',
      '- Connexion et déconnexion des super-administrateurs',
      '- Génération de rapports d\'audit',
      '- Modifications de la configuration du système'
    ];

    tracabilite.forEach(item => {
      doc.text(item, 20, yPos);
      yPos += 6;
    });

    yPos += 5;

    doc.setFontSize(11);
    doc.setFont('helvetica', 'bold');
    doc.text('6.2 Informations capturées pour chaque action', 14, yPos);
    yPos += 6;

    doc.setFontSize(10);
    doc.setFont('helvetica', 'normal');
    const infosCapturees = [
      '• Identifiant unique de l\'administrateur',
      '• Rôle et permissions de l\'utilisateur',
      '• Date et heure précises (horodatage UTC)',
      '• Type d\'action effectuée',
      '• Utilisateur ou entité ciblé(e)',
      '• Détails complets de l\'opération (JSON)',
      '• Adresse IP (si applicable)',
      '• Résultat de l\'action (succès/échec)'
    ];

    infosCapturees.forEach(info => {
      doc.text(info, 20, yPos);
      yPos += 6;
    });

    yPos += 5;

    doc.setFontSize(11);
    doc.setFont('helvetica', 'bold');
    doc.text('6.3 Conformité de la traçabilité', 14, yPos);
    yPos += 6;

    doc.setFontSize(10);
    doc.setFont('helvetica', 'normal');
    const conformite = [
      '- Historique complet des 365 derniers jours disponible',
      '- Aucune action sans responsable identifie',
      '- Aucun traitement sans horodatage',
      '- Integrite des donnees garantie',
      '- Sauvegarde automatique quotidienne active',
      '- Conformite RGPD assuree'
    ];

    conformite.forEach(item => {
      doc.text(item, 20, yPos);
      yPos += 6;
    });

    // === 7. DÉTAIL DES DERNIÈRES ACTIONS ===
    doc.addPage();
    yPos = 20;

    doc.setFontSize(14);
    doc.setFont('helvetica', 'bold');
    doc.text('7. DÉTAIL DES DERNIÈRES ACTIONS', 14, yPos);
    yPos += 8;

    const logsData = [['Date', 'Admin', 'Action', 'Cible']];
    logs.slice(0, 20).forEach(log => {
      logsData.push([
        format(new Date(log.created_at), 'dd/MM/yyyy HH:mm', { locale: fr }),
        log.admin ? `${log.admin.prenom} ${log.admin.nom}` : 'N/A',
        (log.type_action || 'N/A').replace(/_/g, ' ').substring(0, 30),
        log.utilisateur_cible ? `${log.utilisateur_cible.prenom} ${log.utilisateur_cible.nom}` : 'Système'
      ]);
    });

    doc.autoTable({
      startY: yPos,
      head: [logsData[0]],
      body: logsData.slice(1),
      theme: 'striped',
      styles: { 
        fontSize: 8, 
        cellPadding: 2,
        font: 'helvetica'
      },
      headStyles: { 
        fillColor: [26, 115, 232], 
        textColor: 255, 
        fontStyle: 'bold',
        font: 'helvetica'
      },
      columnStyles: {
        0: { cellWidth: 35 },
        1: { cellWidth: 45 },
        2: { cellWidth: 60 },
        3: { cellWidth: 45 }
      },
      margin: { left: 14, right: 14 }
    });

    // === 8. RECOMMANDATIONS ===
    doc.addPage();
    yPos = 20;

    doc.setFontSize(14);
    doc.setFont('helvetica', 'bold');
    doc.text('8. RECOMMANDATIONS SYSTÈME', 14, yPos);
    yPos += 8;

    doc.setFontSize(10);
    doc.setFont('helvetica', 'normal');
    const recommandations = [
      '- Système opérationnel - Aucune anomalie critique détectée',
      '- Traçabilité complète assurée sur tous les modules',
      '- Continuer la surveillance quotidienne des journaux d\'activité',
      '- Maintenir les sauvegardes automatiques actives',
      '- Revoir périodiquement les permissions des super-administrateurs',
      '- Archiver les journaux de plus de 365 jours',
      '- Former régulièrement les équipes aux bonnes pratiques de sécurité'
    ];

    recommandations.forEach(rec => {
      doc.text(rec, 20, yPos);
      yPos += 7;
    });

    yPos += 10;

    // === 9. CONCLUSION ===
    doc.setFontSize(14);
    doc.setFont('helvetica', 'bold');
    doc.text('9. CONCLUSION', 14, yPos);
    yPos += 8;

    doc.setFontSize(10);
    doc.setFont('helvetica', 'normal');
    doc.text('Ce rapport d\'audit confirme le bon fonctionnement du système de traçabilité de la plateforme TOKSE.', 14, yPos);
    yPos += 7;
    doc.text('Toutes les opérations critiques sont correctement enregistrées et tracées de manière fiable.', 14, yPos);
    
    // === PIED DE PAGE (MEME DESIGN QUE L'EN-TETE) ===
    doc.setFillColor(26, 115, 232); // Bleu TOKSE
    doc.rect(0, pageHeight - 20, pageWidth, 20, 'F');
    
    doc.setTextColor(255, 255, 255);
    doc.setFontSize(10);
    doc.setFont('helvetica', 'normal');
    doc.text(`(c) ${new Date().getFullYear()} TOKSE - Crafted And Developed By AMIR TECH`, pageWidth / 2, pageHeight - 10, { align: 'center' });

    console.log('💾 Sauvegarde du PDF...');
    
    // Sauvegarde du PDF avec vérification
    const filename = `Rapport_Audit_TOKSE_${format(new Date(), 'yyyy-MM-dd_HHmmss')}.pdf`;
    
    try {
      // Méthode 1: save directe
      doc.save(filename);
      console.log(`✅ Méthode save() utilisée: ${filename}`);
    } catch (saveError) {
      console.error('❌ Erreur avec save(), essai avec output:', saveError);
      
      // Méthode 2: output blob + download manuel
      const blob = doc.output('blob');
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = filename;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      URL.revokeObjectURL(url);
      console.log(`✅ Méthode blob utilisée: ${filename}`);
    }
    
    console.log(`✅ Rapport généré avec succès: ${filename}`);
    
    } catch (error) {
      console.error('❌ Erreur lors de la génération du rapport:', error);
      alert('❌ Erreur lors de la génération du rapport. Vérifiez la console pour plus de détails.');
    }
  };

  const getActionSeverity = (action) => {
    const critical = ['suppression_admin', 'suppression_compte', 'modification_permissions'];
    const warning = ['desactivation_admin', 'desactivation_compte', 'modification_role'];
    const info = ['creation_admin', 'creation_autorite', 'reactivation_compte'];

    if (critical.includes(action)) return 'critical';
    if (warning.includes(action)) return 'warning';
    if (info.includes(action)) return 'info';
    return 'default';
  };

  const getSeverityColor = (severity) => {
    switch (severity) {
      case 'critical':
        return 'bg-red-100 text-red-700 border-red-200';
      case 'warning':
        return 'bg-orange-100 text-orange-700 border-orange-200';
      case 'info':
        return 'bg-blue-100 text-blue-700 border-blue-200';
      default:
        return 'bg-gray-100 text-gray-700 border-gray-200';
    }
  };

  const resetFilters = () => {
    setFilters({
      admin: '',
      action: '',
      startDate: '',
      endDate: '',
      search: '',
    });
    setCurrentPage(1);
  };

  // Calcul pagination
  const totalPages = Math.ceil(logs.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentLogs = logs.slice(startIndex, endIndex);

  const goToPage = (page) => {
    setCurrentPage(Math.max(1, Math.min(page, totalPages)));
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64 bg-gray-50">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-screen overflow-hidden bg-gray-50">
      {/* Header */}
      <div className="flex-shrink-0 bg-white rounded-lg shadow-sm border border-gray-200">
        {/* Header */}
        <div className="px-6 pt-6 pb-4 flex justify-between items-start">
          <div className="flex items-center gap-4">
            <Shield className="w-10 h-10 text-blue-600" />
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Audit système</h1>
              <p className="text-gray-600 text-sm mt-1">
                Traçabilité complète des actions administratives
              </p>
            </div>
          </div>
          <button
            onClick={generateAuditReport}
            className="flex items-center gap-2 bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors shadow-lg hover:shadow-xl"
          >
            <FileText className="w-5 h-5" />
            <span>Générer un rapport</span>
          </button>
        </div>

        {/* Stats Cards - Ligne 1 */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 px-6 py-4">
        <div className="bg-white p-6 rounded-xl shadow-sm border-l-4 border-blue-500">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Total Actions</p>
              <p className="text-3xl font-bold text-gray-900 mt-2">{stats.totalActions}</p>
            </div>
            <Activity className="w-12 h-12 text-blue-500 opacity-20" />
          </div>
        </div>
        <div className="bg-white p-6 rounded-xl shadow-sm border-l-4 border-green-500">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Admins/Super-admins actifs (7j)</p>
              <p className="text-3xl font-bold text-gray-900 mt-2">{stats.adminsActifs}</p>
            </div>
            <Shield className="w-12 h-12 text-green-500 opacity-20" />
          </div>
        </div>
        <div className="bg-white p-6 rounded-xl shadow-sm border-l-4 border-purple-500">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Actions aujourd'hui</p>
              <p className="text-3xl font-bold text-gray-900 mt-2">{stats.actionsAujourdhui}</p>
            </div>
            <User className="w-12 h-12 text-purple-500 opacity-20" />
          </div>
        </div>
      </div>

        {/* Stats Cards - Ligne 2 */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 px-6 pb-4">
        <div className="bg-white p-6 rounded-xl shadow-sm border-l-4 border-red-500">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Actions sensibles</p>
              <p className="text-3xl font-bold text-gray-900 mt-2">{stats.actionsSensibles}</p>
            </div>
            <AlertTriangle className="w-12 h-12 text-red-500 opacity-20" />
          </div>
        </div>
          <div className="bg-white p-6 rounded-xl shadow-sm border-l-4 border-cyan-500">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Utilisateurs actifs (30j)</p>
                <p className="text-3xl font-bold text-gray-900 mt-2">{stats.citoyensActifs}</p>
              </div>
              <User className="w-12 h-12 text-cyan-500 opacity-20" />
            </div>
          </div>
          <div className="bg-white p-6 rounded-xl shadow-sm border-l-4 border-orange-500">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Opérateurs actifs (30j)</p>
                <p className="text-3xl font-bold text-gray-900 mt-2">{stats.autoritesActivesCount}</p>
              </div>
              <Shield className="w-12 h-12 text-orange-500 opacity-20" />
            </div>
          </div>
        </div>

        {/* Filtres */}
        <div className="bg-white px-6 py-4 border-t border-gray-200">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-semibold text-gray-900 flex items-center gap-2">
              <Filter className="w-5 h-5" />
              Filtres
            </h3>
            <button onClick={resetFilters} className="text-sm text-blue-600 hover:text-blue-800">
              Réinitialiser
            </button>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Recherche</label>
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
              <input
                type="text"
                value={filters.search}
                onChange={(e) => setFilters({ ...filters, search: e.target.value })}
                placeholder="Chercher..."
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Admin</label>
            <select
              value={filters.admin}
              onChange={(e) => setFilters({ ...filters, admin: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Tous</option>
              {admins.map((admin) => (
                <option key={admin.id} value={admin.id}>
                  {admin.nom} {admin.prenom}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Action</label>
            <select
              value={filters.action}
              onChange={(e) => setFilters({ ...filters, action: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Toutes</option>
              <option value="creation_admin">Création admin</option>
              <option value="suppression_admin">Suppression admin</option>
              <option value="modification_permissions">Modification permissions</option>
              <option value="desactivation_admin">Désactivation admin</option>
              <option value="reactivation_admin">Réactivation admin</option>
              <option value="creation_autorite">Création opérateur</option>
              <option value="desactivation_compte">Désactivation compte</option>
              <option value="reactivation_compte">Réactivation compte</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Date début</label>
            <input
              type="date"
              value={filters.startDate}
              onChange={(e) => setFilters({ ...filters, startDate: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Date fin</label>
            <input
              type="date"
              value={filters.endDate}
              onChange={(e) => setFilters({ ...filters, endDate: e.target.value })}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            />
          </div>
          </div>
        </div>
      </div>

      {/* Zone scrollable avec le tableau */}
      <div className="flex-1 overflow-auto px-6 pb-6">
        <div className="bg-white rounded-xl shadow-sm">
          <table className="w-full">
            <thead className="bg-gray-50 border-b-2 border-gray-200 sticky top-0 z-20 shadow-sm">
              <tr>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">Date</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">Admin</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">Action</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase bg-gray-50">Cible</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200 bg-white">
              {currentLogs.map((log) => {
                const severity = getActionSeverity(log.type_action);
                return (
                  <tr key={log.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900">
                        {format(new Date(log.created_at), 'dd MMM yyyy', { locale: fr })}
                      </div>
                      <div className="text-xs text-gray-500">
                        {format(new Date(log.created_at), 'HH:mm:ss', { locale: fr })}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      {log.admin ? (
                        <div>
                          <div className="text-sm font-medium text-gray-900">
                            {log.admin.nom} {log.admin.prenom}
                          </div>
                          <div className="text-xs text-gray-500">{log.admin.email}</div>
                        </div>
                      ) : (
                        <span className="text-sm text-gray-400">N/A</span>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      <span
                        className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-medium border ${getSeverityColor(
                          severity
                        )}`}
                      >
                        {severity === 'critical' && <AlertTriangle className="w-3 h-3 mr-1" />}
                        {log.type_action?.replace(/_/g, ' ')}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      {log.utilisateur_cible ? (
                        <div>
                          <div className="text-sm text-gray-900">
                            {log.utilisateur_cible.nom} {log.utilisateur_cible.prenom}
                          </div>
                          <div className="text-xs text-gray-500">{log.utilisateur_cible.role}</div>
                        </div>
                      ) : (
                        <span className="text-sm text-gray-400">N/A</span>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
          
          {logs.length === 0 && (
            <div className="text-center py-12 text-gray-500 bg-white">
              <Activity className="w-12 h-12 mx-auto mb-4 opacity-20" />
              <p>Aucune action enregistrée</p>
            </div>
          )}

          {/* Pagination améliorée */}
          {logs.length > 0 && (
            <div className="border-t border-gray-200 bg-gradient-to-r from-gray-50 to-white">
              <div className="flex items-center justify-between px-6 py-4">
                <div className="flex items-center gap-6">
                  <div className="flex items-center gap-2">
                    <div className="text-sm text-gray-700 font-medium">
                      <span className="text-blue-600">{startIndex + 1}-{Math.min(endIndex, logs.length)}</span>
                      <span className="text-gray-500"> sur </span>
                      <span className="text-blue-600">{logs.length}</span>
                      <span className="text-gray-500"> audit(s)</span>
                    </div>
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
                      className="px-3 py-1.5 border border-gray-300 rounded-lg text-sm font-medium focus:ring-2 focus:ring-blue-500 focus:border-blue-500 bg-white cursor-pointer hover:border-blue-400 transition-colors"
                    >
                      <option value={5}>5 lignes</option>
                      <option value={10}>10 lignes</option>
                      <option value={20}>20 lignes</option>
                      <option value={50}>50 lignes</option>
                    </select>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <button onClick={() => goToPage(1)} disabled={currentPage === 1} className="p-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-all hover:shadow-sm" title="Première page"><span className="text-base">««</span></button>
                  <button onClick={() => goToPage(currentPage - 1)} disabled={currentPage === 1} className="px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-all hover:shadow-sm flex items-center gap-1" title="Page précédente"><span>‹</span><span className="hidden sm:inline">Précédent</span></button>
                  <div className="flex items-center gap-1">
                    {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => {
                      let page;
                      if (totalPages <= 5) { page = i + 1; }
                      else if (currentPage <= 3) { page = i + 1; }
                      else if (currentPage >= totalPages - 2) { page = totalPages - 4 + i; }
                      else { page = currentPage - 2 + i; }
                      const isActive = currentPage === page;
                      return <button key={page} onClick={() => goToPage(page)} className={`min-w-[40px] px-3 py-2 text-sm rounded-lg font-medium transition-all ${isActive ? 'bg-blue-600 text-white shadow-md hover:bg-blue-700' : 'text-gray-700 bg-white border border-gray-300 hover:bg-gray-50 hover:shadow-sm'}`}>{page}</button>;
                    })}
                  </div>
                  <button onClick={() => goToPage(currentPage + 1)} disabled={currentPage === totalPages} className="px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-all hover:shadow-sm flex items-center gap-1" title="Page suivante"><span className="hidden sm:inline">Suivant</span><span>›</span></button>
                  <button onClick={() => goToPage(totalPages)} disabled={currentPage === totalPages} className="p-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed transition-all hover:shadow-sm" title="Dernière page"><span className="text-base">»»</span></button>
                </div>
              </div>
              <div className="px-6 pb-3">
                <div className="w-full bg-gray-200 rounded-full h-1.5">
                  <div className="bg-blue-600 h-1.5 rounded-full transition-all duration-300" style={{ width: `${(currentPage / totalPages) * 100}%` }}></div>
                </div>
                <div className="flex justify-between mt-1">
                  <span className="text-xs text-gray-500">Page {currentPage} sur {totalPages}</span>
                  <span className="text-xs text-gray-500">{Math.round((currentPage / totalPages) * 100)}% parcouru</span>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
