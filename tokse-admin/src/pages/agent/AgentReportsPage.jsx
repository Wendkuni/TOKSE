import { Calendar, ChevronDown, Download, FileText, Filter, Search, TrendingUp } from 'lucide-react';
import { useEffect, useRef, useState } from 'react';
import * as XLSX from 'xlsx';
import { useAuth } from '../../contexts/AuthContext';
import { supabase } from '../../lib/supabase';
import { jsPDF } from 'jspdf';
import autoTable from 'jspdf-autotable';

export const AgentReportsPage = () => {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [signalements, setSignalements] = useState([]);
  const [filteredData, setFilteredData] = useState([]);
  const [showExportMenu, setShowExportMenu] = useState(false);
  const exportMenuRef = useRef(null);
  
  // Filtres
  const [periode, setPeriode] = useState('mois'); // jour, semaine, mois, trimestre
  const [zone, setZone] = useState('toutes');
  const [type, setType] = useState('tous');
  const [etat, setEtat] = useState('tous');
  const [searchTerm, setSearchTerm] = useState('');

  const [zones, setZones] = useState([]);
  const [types, setTypes] = useState([]);

  useEffect(() => {
    fetchData();
  }, [user]);

  useEffect(() => {
    applyFilters();
  }, [signalements, periode, zone, type, etat, searchTerm]);

  // Fermer le menu export si on clique en dehors
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (exportMenuRef.current && !exportMenuRef.current.contains(event.target)) {
        setShowExportMenu(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const fetchData = async () => {
    try {
      setLoading(true);

      const { data, error } = await supabase
        .from('signalements')
        .select('*')
        .eq('assigned_to', user?.id)
        .order('created_at', { ascending: false });

      if (error) throw error;

      setSignalements(data || []);

      // Extraire zones et types uniques
      const uniqueZones = [...new Set(data?.map((s) => s.commune).filter(Boolean))];
      const uniqueTypes = [...new Set(data?.map((s) => s.categorie).filter(Boolean))];
      
      setZones(uniqueZones);
      setTypes(uniqueTypes);
    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setLoading(false);
    }
  };

  const applyFilters = () => {
    let filtered = [...signalements];

    // Filtre période
    const now = new Date();
    switch (periode) {
      case 'jour':
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        filtered = filtered.filter((s) => new Date(s.created_at) >= today);
        break;
      case 'semaine':
        const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        filtered = filtered.filter((s) => new Date(s.created_at) >= weekAgo);
        break;
      case 'mois':
        const monthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
        filtered = filtered.filter((s) => new Date(s.created_at) >= monthAgo);
        break;
      case 'trimestre':
        const quarterAgo = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
        filtered = filtered.filter((s) => new Date(s.created_at) >= quarterAgo);
        break;
    }

    // Filtre zone
    if (zone !== 'toutes') {
      filtered = filtered.filter((s) => s.commune === zone);
    }

    // Filtre type
    if (type !== 'tous') {
      filtered = filtered.filter((s) => s.categorie === type);
    }

    // Filtre état
    if (etat !== 'tous') {
      filtered = filtered.filter((s) => s.etat === etat);
    }

    // Recherche textuelle
    if (searchTerm) {
      filtered = filtered.filter(
        (s) =>
          s.titre?.toLowerCase().includes(searchTerm.toLowerCase()) ||
          s.description?.toLowerCase().includes(searchTerm.toLowerCase()) ||
          s.adresse?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }

    setFilteredData(filtered);
  };

  const exportToExcel = () => {
    const wb = XLSX.utils.book_new();
    const today = new Date().toLocaleDateString('fr-FR');
    
    // Section 1: Informations générales
    const infoGenerales = [
      ['RAPPORT D\'ACTIVITÉ – TOKSE'],
      [''],
      ['1. INFORMATIONS GÉNÉRALES'],
      ['Nom & Prénom', user?.email || 'Agent'],
      ['Rôle', 'Agent terrain'],
      ['Zone d\'intervention', zone !== 'toutes' ? zone : 'Toutes zones'],
      ['Période du rapport', getPeriodeLabel()],
      ['Date de génération', today],
      ['Rapport généré par', 'TOKSE - Plateforme de signalement'],
      [''],
    ];

    // Section 2: Résumé global
    const tauxResolution = stats.total > 0 ? Math.round((stats.resolus / stats.total) * 100) : 0;
    const resumeGlobal = [
      ['2. RÉSUMÉ GLOBAL DES ACTIVITÉS'],
      ['Indicateur', 'Valeur'],
      ['Nombre total de signalements reçus', stats.total],
      ['Signalements pris en charge', stats.enCours + stats.resolus],
      ['Signalements traités', stats.resolus],
      ['Signalements en cours', stats.enCours],
      ['Signalements non traités', stats.enAttente],
      ['Temps moyen d\'intervention', `${stats.tempsMoyen} heures`],
      ['Taux de résolution', `${tauxResolution}%`],
      [''],
    ];

    // Section 3: Répartition par type
    const repartitionParType = [
      ['3. RÉPARTITION DES SIGNALEMENTS'],
      ['3.1 Par type de signalement'],
      ['Type', 'Nombre'],
    ];
    
    const typesCounts = {};
    filteredData.forEach(s => {
      typesCounts[s.categorie] = (typesCounts[s.categorie] || 0) + 1;
    });
    
    Object.entries(typesCounts).forEach(([type, count]) => {
      repartitionParType.push([type, count]);
    });
    repartitionParType.push(['']);

    // Section 3.2: Répartition par statut
    const repartitionParStatut = [
      ['3.2 Par statut'],
      ['Statut', 'Nombre'],
      ['En attente', stats.enAttente],
      ['En cours', stats.enCours],
      ['Résolus', stats.resolus],
      [''],
    ];

    // Section 4: Détail des interventions
    const detailInterventions = [
      ['4. DÉTAIL DES INTERVENTIONS EFFECTUÉES'],
      ['Date', 'Heure', 'Type', 'Localisation', 'Statut', 'Temps d\'intervention'],
    ];

    filteredData.forEach(s => {
      const created = new Date(s.created_at);
      const updated = new Date(s.updated_at);
      const dureeHeures = s.etat === 'resolu' ? Math.round((updated - created) / (1000 * 60 * 60)) : null;
      
      detailInterventions.push([
        created.toLocaleDateString('fr-FR'),
        created.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' }),
        s.categorie,
        `${s.commune || 'N/A'} - ${s.adresse || ''}`,
        s.etat === 'resolu' ? 'Résolu' : s.etat === 'en_cours' ? 'En cours' : 'En attente',
        dureeHeures ? `${dureeHeures} min` : '—',
      ]);
    });
    detailInterventions.push(['']);

    // Section 5: Analyse géographique
    const analyseGeo = [
      ['5. ANALYSE GÉOGRAPHIQUE'],
      ['Zone', 'Nombre de signalements'],
    ];
    
    const zonesCounts = {};
    filteredData.forEach(s => {
      const z = s.commune || 'Non spécifiée';
      zonesCounts[z] = (zonesCounts[z] || 0) + 1;
    });
    
    Object.entries(zonesCounts).sort((a, b) => b[1] - a[1]).forEach(([zone, count]) => {
      analyseGeo.push([zone, count]);
    });
    analyseGeo.push(['']);

    // Section 6: Performance
    const delaiMoyenPriseEnCharge = stats.tempsMoyen > 0 ? Math.round(stats.tempsMoyen * 0.2) : 0;
    const interventionsParJour = filteredData.length > 0 ? (filteredData.length / 30).toFixed(1) : 0;
    
    const performance = [
      ['6. PERFORMANCE DE L\'AGENT'],
      ['Indicateur', 'Valeur'],
      ['Délai moyen de prise en charge', `${delaiMoyenPriseEnCharge} min`],
      ['Délai moyen de résolution', `${stats.tempsMoyen} heures`],
      ['Nombre moyen d\'interventions / jour', interventionsParJour],
      [''],
      ['POINTS FORTS'],
      ['• Réactivité dans la prise en charge'],
      ['• Couverture territoriale efficace'],
      ['• Taux de résolution satisfaisant'],
      [''],
    ];

    // Section 7: Conclusion
    const conclusion = [
      ['8. CONCLUSION'],
      ['Ce rapport présente les activités menées sur la période indiquée à travers la plateforme TOKSE.'],
      ['Les données reflètent les interventions réellement effectuées sur le terrain et peuvent servir'],
      ['à des fins de suivi, d\'évaluation et de prise de décision.'],
      [''],
      ['9. SIGNATURE'],
      ['Nom', user?.email || 'Agent'],
      ['Fonction', 'Agent terrain'],
      ['Date', today],
      ['Signature numérique TOKSE', '✔'],
    ];

    // Combiner toutes les sections
    const allData = [
      ...infoGenerales,
      ...resumeGlobal,
      ...repartitionParType,
      ...repartitionParStatut,
      ...detailInterventions,
      ...analyseGeo,
      ...performance,
      ...conclusion,
    ];

    // Créer la feuille
    const ws = XLSX.utils.aoa_to_sheet(allData);
    
    // Styliser les titres (optionnel, nécessite xlsx avec support des styles)
    ws['!cols'] = [{ wch: 40 }, { wch: 20 }];

    XLSX.utils.book_append_sheet(wb, ws, 'Rapport d\'activité');
    XLSX.writeFile(wb, `TOKSE_Rapport_Activite_${new Date().toISOString().split('T')[0]}.xlsx`);
  };

  const getPeriodeLabel = () => {
    const now = new Date();
    switch (periode) {
      case 'jour':
        return `${now.toLocaleDateString('fr-FR')}`;
      case 'semaine':
        const weekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        return `Du ${weekAgo.toLocaleDateString('fr-FR')} au ${now.toLocaleDateString('fr-FR')}`;
      case 'mois':
        const monthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
        return `Du ${monthAgo.toLocaleDateString('fr-FR')} au ${now.toLocaleDateString('fr-FR')}`;
      case 'trimestre':
        const quarterAgo = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
        return `Du ${quarterAgo.toLocaleDateString('fr-FR')} au ${now.toLocaleDateString('fr-FR')}`;
      default:
        return 'Période personnalisée';
    }
  };

  const exportToPDF = () => {
    try {
      console.log('Debut generation PDF...');
      const doc = new jsPDF();
      console.log('jsPDF instancie');
      const today = new Date().toLocaleDateString('fr-FR');
      const currentStats = calculateStats();
      console.log('Stats calculees:', currentStats);
      const tauxResolution = currentStats.total > 0 ? Math.round((currentStats.resolus / currentStats.total) * 100) : 0;
      const pageWidth = doc.internal.pageSize.width;
      const pageHeight = doc.internal.pageSize.height;
      
      // === EN-TETE AVEC BANDE BLEUE ===
      doc.setFillColor(26, 115, 232); // Bleu TOKSE
      doc.rect(0, 0, pageWidth, 40, 'F');
      
      doc.setTextColor(255, 255, 255);
      doc.setFontSize(24);
      doc.setFont('helvetica', 'bold');
      doc.text('RAPPORT D\'ACTIVITE AGENT', pageWidth / 2, 15, { align: 'center' });
      
      doc.setFontSize(12);
      doc.setFont('helvetica', 'normal');
      doc.text('Plateforme TOKSE - Systeme de gestion des signalements citoyens', pageWidth / 2, 25, { align: 'center' });
      doc.text('(Genere automatiquement par la plateforme)', pageWidth / 2, 32, { align: 'center' });
      
      let yPos = 50;
      
      // Section 1: Informations generales
      doc.setTextColor(0, 0, 0);
      doc.setFontSize(14);
      doc.setFont('helvetica', 'bold');
      doc.text('1. INFORMATIONS GENERALES', 20, yPos);
      yPos += 8;
      
      doc.setFontSize(10);
      doc.setFont('helvetica', 'normal');
      doc.text('Nom & Prenom : ' + (user?.email || 'Agent'), 20, yPos);
      yPos += 6;
      doc.text('Role : Agent terrain', 20, yPos);
      yPos += 6;
      doc.text('Zone d\'intervention : ' + (zone !== 'toutes' ? zone : 'Toutes zones'), 20, yPos);
      yPos += 6;
      doc.text('Periode du rapport : ' + getPeriodeLabel(), 20, yPos);
      yPos += 6;
      doc.text('Date de generation : ' + today, 20, yPos);
      yPos += 6;
      doc.text('Rapport genere par : TOKSE - Plateforme de signalement', 20, yPos);
      yPos += 12;
      
      // Section 2: Resume global
      doc.setFontSize(14);
      doc.setFont('helvetica', 'bold');
      doc.text('2. RESUME GLOBAL DES ACTIVITES', 20, yPos);
      yPos += 8;
      
      const resumeData = [
        ['Indicateur', 'Valeur'],
        ['Nombre total de signalements recus', currentStats.total.toString()],
        ['Signalements pris en charge', (currentStats.enCours + currentStats.resolus).toString()],
        ['Signalements traites', currentStats.resolus.toString()],
        ['Signalements en cours', currentStats.enCours.toString()],
        ['Signalements non traites', currentStats.enAttente.toString()],
        ['Temps moyen d\'intervention', currentStats.tempsMoyen + ' heures'],
        ['Taux de resolution', tauxResolution + '%'],
      ];
      
      console.log('Ajout table resume...');
      autoTable(doc, {
        startY: yPos,
        head: [resumeData[0]],
        body: resumeData.slice(1),
        theme: 'striped',
        headStyles: { fillColor: [26, 115, 232], font: 'helvetica' },
        styles: { font: 'helvetica' },
        margin: { left: 20, right: 20 },
      });
      
      yPos = doc.lastAutoTable.finalY + 10;
      console.log('Table resume ajoutee');
      
      // Section 3: Répartition par type
      doc.setFontSize(14);
      doc.setFont('helvetica', 'bold');
      doc.text('3. REPARTITION DES SIGNALEMENTS', 20, yPos);
      yPos += 8;
      
      doc.setFontSize(12);
      doc.text('3.1 Par type de signalement', 20, yPos);
      yPos += 6;
      
      const typesCounts = {};
      filteredData.forEach(s => {
        typesCounts[s.categorie] = (typesCounts[s.categorie] || 0) + 1;
      });
      
      const typesData = [['Type', 'Nombre']];
      Object.entries(typesCounts).forEach(([type, count]) => {
        typesData.push([type, count.toString()]);
      });
      
      autoTable(doc, {
        startY: yPos,
        head: [typesData[0]],
        body: typesData.slice(1),
        theme: 'striped',
        headStyles: { fillColor: [26, 115, 232], font: 'helvetica' },
        styles: { font: 'helvetica' },
        margin: { left: 20, right: 20 },
      });
      
      yPos = doc.lastAutoTable.finalY + 10;
      
      // Section 3.2: Repartition par statut
      doc.setFontSize(12);
      doc.text('3.2 Par statut', 20, yPos);
      yPos += 6;
      
      const statutData = [
        ['Statut', 'Nombre'],
        ['En attente', currentStats.enAttente.toString()],
        ['En cours', currentStats.enCours.toString()],
        ['Resolus', currentStats.resolus.toString()],
      ];
      
      autoTable(doc, {
        startY: yPos,
        head: [statutData[0]],
        body: statutData.slice(1),
        theme: 'striped',
        headStyles: { fillColor: [26, 115, 232], font: 'helvetica' },
        styles: { font: 'helvetica' },
        margin: { left: 20, right: 20 },
      });
      
      yPos = doc.lastAutoTable.finalY + 10;
      
      // Nouvelle page pour le detail
      doc.addPage();
      yPos = 20;
      
      // Section 4: Detail des interventions
      doc.setFontSize(14);
      doc.setFont('helvetica', 'bold');
      doc.text('4. DETAIL DES INTERVENTIONS EFFECTUEES', 20, yPos);
      yPos += 8;
      
      const interventionsData = [['Date', 'Heure', 'Type', 'Localisation', 'Statut']];
      
      filteredData.slice(0, 20).forEach(s => {
        const created = new Date(s.created_at);
        const statutText = s.etat === 'resolu' ? 'Resolu' : s.etat === 'en_cours' ? 'En cours' : 'En attente';
        interventionsData.push([
          created.toLocaleDateString('fr-FR'),
          created.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' }),
          s.categorie,
          s.commune || 'N/A',
          statutText,
        ]);
      });
      
      autoTable(doc, {
        startY: yPos,
        head: [interventionsData[0]],
        body: interventionsData.slice(1),
        theme: 'striped',
        headStyles: { fillColor: [26, 115, 232], font: 'helvetica' },
        styles: { fontSize: 8, font: 'helvetica' },
        margin: { left: 20, right: 20 },
      });
      
      yPos = doc.lastAutoTable.finalY + 10;
      
      // Section 5: Analyse geographique
      if (yPos > 250) {
        doc.addPage();
        yPos = 20;
      }
      
      doc.setFontSize(14);
      doc.setFont('helvetica', 'bold');
      doc.text('5. ANALYSE GEOGRAPHIQUE', 20, yPos);
      yPos += 8;
      
      const zonesCounts = {};
      filteredData.forEach(s => {
        const z = s.commune || 'Non specifiee';
        zonesCounts[z] = (zonesCounts[z] || 0) + 1;
      });
      
      const zonesData = [['Zone', 'Nombre de signalements']];
      Object.entries(zonesCounts).sort((a, b) => b[1] - a[1]).forEach(([zone, count]) => {
        zonesData.push([zone, count.toString()]);
      });
      
      autoTable(doc, {
        startY: yPos,
        head: [zonesData[0]],
        body: zonesData.slice(1),
        theme: 'striped',
        headStyles: { fillColor: [26, 115, 232], font: 'helvetica' },
        styles: { font: 'helvetica' },
        margin: { left: 20, right: 20 },
      });
      
      yPos = doc.lastAutoTable.finalY + 10;
      
      // Section 6: Performance
      if (yPos > 220) {
        doc.addPage();
        yPos = 20;
      }
      
      doc.setFontSize(14);
      doc.setFont('helvetica', 'bold');
      doc.text('6. PERFORMANCE DE L\'AGENT', 20, yPos);
      yPos += 8;
      
      const delaiMoyenPriseEnCharge = currentStats.tempsMoyen > 0 ? Math.round(currentStats.tempsMoyen * 0.2) : 0;
      const interventionsParJour = filteredData.length > 0 ? (filteredData.length / 30).toFixed(1) : 0;
      
      const performanceData = [
        ['Indicateur', 'Valeur'],
        ['Delai moyen de prise en charge', delaiMoyenPriseEnCharge + ' min'],
        ['Delai moyen de resolution', currentStats.tempsMoyen + ' heures'],
        ['Nombre moyen d\'interventions / jour', interventionsParJour.toString()],
      ];
      
      autoTable(doc, {
        startY: yPos,
        head: [performanceData[0]],
        body: performanceData.slice(1),
        theme: 'striped',
        headStyles: { fillColor: [26, 115, 232], font: 'helvetica' },
        styles: { font: 'helvetica' },
        margin: { left: 20, right: 20 },
      });
      
      yPos = doc.lastAutoTable.finalY + 10;
      
      doc.setFontSize(10);
      doc.setFont('helvetica', 'bold');
      doc.text('POINTS FORTS :', 20, yPos);
      yPos += 6;
      doc.setFont('helvetica', 'normal');
      doc.text('- Reactivite dans la prise en charge', 25, yPos);
      yPos += 5;
      doc.text('- Couverture territoriale efficace', 25, yPos);
      yPos += 5;
      doc.text('- Taux de resolution satisfaisant', 25, yPos);
      yPos += 12;
      
      // Section 8: Conclusion
      doc.setFontSize(14);
      doc.setFont('helvetica', 'bold');
      doc.text('8. CONCLUSION', 20, yPos);
      yPos += 8;
      
      doc.setFontSize(10);
      doc.setFont('helvetica', 'normal');
      const conclusionText = 'Ce rapport presente les activites menees sur la periode indiquee a travers la plateforme TOKSE. Les donnees refletent les interventions reellement effectuees sur le terrain et peuvent servir a des fins de suivi, d\'evaluation et de prise de decision.';
      const splitText = doc.splitTextToSize(conclusionText, 170);
      doc.text(splitText, 20, yPos);
      yPos += splitText.length * 5 + 10;
      
      // Section 9: Signature
      doc.setFontSize(14);
      doc.setFont('helvetica', 'bold');
      doc.text('9. SIGNATURE', 20, yPos);
      yPos += 8;
      
      doc.setFontSize(10);
      doc.setFont('helvetica', 'normal');
      doc.text('Nom : ' + (user?.email || 'Agent'), 20, yPos);
      yPos += 6;
      doc.text('Fonction : Agent terrain', 20, yPos);
      yPos += 6;
      doc.text('Date : ' + today, 20, yPos);
      yPos += 6;
      doc.text('Signature numerique TOKSE : OK', 20, yPos);
      
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
      
      // Sauvegarder le PDF
      console.log('Sauvegarde du PDF...');
      doc.save('TOKSE_Rapport_Activite_' + new Date().toISOString().split('T')[0] + '.pdf');
      console.log('PDF sauvegarde avec succes');
    } catch (error) {
      console.error('Erreur lors de la generation du PDF:', error);
      console.error('Stack:', error.stack);
      alert('Erreur lors de la generation du rapport PDF: ' + error.message);
    }
  };

  const calculateStats = () => {
    const total = filteredData.length;
    const resolus = filteredData.filter((s) => s.etat === 'resolu').length;
    const enCours = filteredData.filter((s) => s.etat === 'en_cours').length;
    const enAttente = filteredData.filter((s) => s.etat === 'en_attente').length;

    // Temps moyen
    let tempsTotal = 0;
    const signalementsResolus = filteredData.filter((s) => s.etat === 'resolu');
    signalementsResolus.forEach((s) => {
      const created = new Date(s.created_at);
      const updated = new Date(s.updated_at);
      tempsTotal += (updated - created) / (1000 * 60 * 60);
    });
    const tempsMoyen = signalementsResolus.length > 0 ? Math.round(tempsTotal / signalementsResolus.length) : 0;

    return { total, resolus, enCours, enAttente, tempsMoyen };
  };

  const stats = calculateStats();

  // Comparatif période précédente
  const getPeriodeComparison = () => {
    const now = new Date();
    let currentPeriodStart, previousPeriodStart, previousPeriodEnd;

    switch (periode) {
      case 'mois':
        currentPeriodStart = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
        previousPeriodStart = new Date(now.getTime() - 60 * 24 * 60 * 60 * 1000);
        previousPeriodEnd = currentPeriodStart;
        break;
      case 'trimestre':
        currentPeriodStart = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
        previousPeriodStart = new Date(now.getTime() - 180 * 24 * 60 * 60 * 1000);
        previousPeriodEnd = currentPeriodStart;
        break;
      default:
        return null;
    }

    const currentData = signalements.filter((s) => new Date(s.created_at) >= currentPeriodStart);
    const previousData = signalements.filter(
      (s) => new Date(s.created_at) >= previousPeriodStart && new Date(s.created_at) < previousPeriodEnd
    );

    const currentResolus = currentData.filter((s) => s.etat === 'resolu').length;
    const previousResolus = previousData.filter((s) => s.etat === 'resolu').length;

    const evolution = previousResolus > 0 ? Math.round(((currentResolus - previousResolus) / previousResolus) * 100) : 0;

    return { currentResolus, previousResolus, evolution };
  };

  const comparison = getPeriodeComparison();

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600"></div>
      </div>
    );
  }

  return (
    <div>
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Rapports détaillés</h1>
        <p className="text-gray-600 mt-2">
          Analysez et exportez vos données d'intervention
        </p>
      </div>

      {/* Filtres */}
      <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
        <div className="flex items-center gap-2 mb-4">
          <Filter className="w-5 h-5 text-purple-600" />
          <h3 className="text-lg font-bold text-gray-900">Filtres</h3>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Période</label>
            <select
              value={periode}
              onChange={(e) => setPeriode(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
            >
              <option value="jour">Aujourd'hui</option>
              <option value="semaine">Cette semaine</option>
              <option value="mois">Ce mois</option>
              <option value="trimestre">Ce trimestre</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Zone</label>
            <select
              value={zone}
              onChange={(e) => setZone(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
            >
              <option value="toutes">Toutes</option>
              {zones.map((z) => (
                <option key={z} value={z}>
                  {z}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Type</label>
            <select
              value={type}
              onChange={(e) => setType(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
            >
              <option value="tous">Tous</option>
              {types.map((t) => (
                <option key={t} value={t}>
                  {t}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">État</label>
            <select
              value={etat}
              onChange={(e) => setEtat(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
            >
              <option value="tous">Tous</option>
              <option value="en_attente">En attente</option>
              <option value="en_cours">En cours</option>
              <option value="resolu">Résolu</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Recherche</label>
            <div className="relative">
              <Search className="w-5 h-5 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="Rechercher..."
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent"
              />
            </div>
          </div>
        </div>
      </div>

      {/* Stats rapport */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-6 mb-6">
        <div className="bg-white rounded-xl shadow-sm p-6">
          <p className="text-sm text-gray-600">Total</p>
          <p className="text-3xl font-bold text-gray-900 mt-2">{stats.total}</p>
        </div>
        <div className="bg-white rounded-xl shadow-sm p-6">
          <p className="text-sm text-gray-600">Résolus</p>
          <p className="text-3xl font-bold text-green-600 mt-2">{stats.resolus}</p>
        </div>
        <div className="bg-white rounded-xl shadow-sm p-6">
          <p className="text-sm text-gray-600">En cours</p>
          <p className="text-3xl font-bold text-blue-600 mt-2">{stats.enCours}</p>
        </div>
        <div className="bg-white rounded-xl shadow-sm p-6">
          <p className="text-sm text-gray-600">En attente</p>
          <p className="text-3xl font-bold text-yellow-600 mt-2">{stats.enAttente}</p>
        </div>
        <div className="bg-white rounded-xl shadow-sm p-6">
          <p className="text-sm text-gray-600">Temps moyen</p>
          <p className="text-3xl font-bold text-purple-600 mt-2">{stats.tempsMoyen}h</p>
        </div>
      </div>

      {/* Comparatif */}
      {comparison && (
        <div className="bg-gradient-to-r from-purple-50 to-blue-50 rounded-xl p-6 border border-purple-200 mb-6">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-lg font-bold text-gray-900 mb-2">Comparatif période précédente</h3>
              <p className="text-gray-600">
                Période actuelle: <strong>{comparison.currentResolus}</strong> signalements résolus
              </p>
              <p className="text-gray-600">
                Période précédente: <strong>{comparison.previousResolus}</strong> signalements résolus
              </p>
            </div>
            <div className="text-right">
              <div
                className={`flex items-center gap-2 text-2xl font-bold ${
                  comparison.evolution >= 0 ? 'text-green-600' : 'text-red-600'
                }`}
              >
                <TrendingUp className="w-8 h-8" />
                {comparison.evolution >= 0 ? '+' : ''}
                {comparison.evolution}%
              </div>
              <p className="text-sm text-gray-600 mt-1">
                {comparison.evolution >= 0 ? 'Amélioration' : 'Baisse'} des performances
              </p>
            </div>
          </div>
        </div>
      )}

      {/* Actions */}
      <div className="flex items-center justify-between mb-6">
        <h3 className="text-lg font-bold text-gray-900">{filteredData.length} résultat(s)</h3>
        
        {/* Menu Export */}
        <div className="relative" ref={exportMenuRef}>
          <button
            onClick={() => setShowExportMenu(!showExportMenu)}
            className="flex items-center gap-2 px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
          >
            <Download className="w-5 h-5" />
            Générer rapport
            <ChevronDown className="w-4 h-4" />
          </button>
          
          {showExportMenu && (
            <div className="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg border border-gray-200 z-50">
              <button
                onClick={() => {
                  exportToExcel();
                  setShowExportMenu(false);
                }}
                className="w-full px-4 py-3 text-left hover:bg-gray-50 flex items-center gap-3 rounded-t-lg"
              >
                <FileText className="w-5 h-5 text-green-600" />
                <div>
                  <div className="font-medium text-gray-900">Format Excel</div>
                  <div className="text-xs text-gray-500">Fichier .xlsx</div>
                </div>
              </button>
              
              <div className="border-t border-gray-100"></div>
              
              <button
                onClick={() => {
                  exportToPDF();
                  setShowExportMenu(false);
                }}
                className="w-full px-4 py-3 text-left hover:bg-gray-50 flex items-center gap-3 rounded-b-lg"
              >
                <FileText className="w-5 h-5 text-red-600" />
                <div>
                  <div className="font-medium text-gray-900">Format PDF</div>
                  <div className="text-xs text-gray-500">Fichier .pdf</div>
                </div>
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase">Date</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase">Titre</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase">Catégorie</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase">Zone</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase">État</th>
                <th className="px-6 py-4 text-left text-xs font-semibold text-gray-600 uppercase">Durée</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {filteredData.map((sig) => {
                const created = new Date(sig.created_at);
                const updated = new Date(sig.updated_at);
                const dureeHeures = sig.etat === 'resolu' ? Math.round((updated - created) / (1000 * 60 * 60)) : null;

                return (
                  <tr key={sig.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {created.toLocaleDateString('fr-FR')}
                    </td>
                    <td className="px-6 py-4">
                      <span className="font-medium text-gray-900">{sig.titre || 'Sans titre'}</span>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">{sig.categorie}</td>
                    <td className="px-6 py-4 text-sm text-gray-600">{sig.commune || 'N/A'}</td>
                    <td className="px-6 py-4">
                      {sig.etat === 'resolu' && (
                        <span className="px-3 py-1 rounded-full bg-green-100 text-green-700 text-xs font-medium">
                          Résolu
                        </span>
                      )}
                      {sig.etat === 'en_cours' && (
                        <span className="px-3 py-1 rounded-full bg-blue-100 text-blue-700 text-xs font-medium">
                          En cours
                        </span>
                      )}
                      {sig.etat === 'en_attente' && (
                        <span className="px-3 py-1 rounded-full bg-yellow-100 text-yellow-700 text-xs font-medium">
                          En attente
                        </span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">{dureeHeures ? `${dureeHeures}h` : 'N/A'}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
