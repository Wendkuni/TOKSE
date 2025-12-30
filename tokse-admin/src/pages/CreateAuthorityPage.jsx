import { AlertCircle, CheckCircle, Mail, Phone, Shield, User, UserPlus } from 'lucide-react';
import { useState } from 'react';

export const CreateAuthorityPage = () => {
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState('');
  const [formData, setFormData] = useState({
    nom: '',
    prenom: '',
    email: '',
    numero_telephone: '',
    role: 'police_municipale',
    zone_intervention: '',
    password: '',
  });

  const roles = [
    { value: 'police_municipale', label: 'Police Municipale' },
    { value: 'mairie', label: 'Mairie' },
    { value: 'hygiene', label: 'Service d\'Hygiène' },
    { value: 'voirie', label: 'Service de Voirie' },
    { value: 'environnement', label: 'Service Environnement' },
    { value: 'securite', label: 'Service de Sécurité' },
  ];

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess(false);
    setLoading(true);



    try {
      console.log('[DEBUG] Données du formulaire envoyées :', formData);
      // Appel à l'API locale pour créer l'autorité sans déconnecter l'admin
      const response = await fetch('http://localhost:4000/api/create-authority', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      });
      const result = await response.json();
      if (!response.ok) {
        console.error('[DEBUG] Erreur API:', result.error);
        throw new Error(result.error || 'Erreur lors de la création de l\'autorité');
      }

      setSuccess(true);
      setFormData({
        nom: '',
        prenom: '',
        email: '',
        numero_telephone: '',
        role: 'police_municipale',
        zone_intervention: '',
        password: '',
      });

      setTimeout(() => setSuccess(false), 5000);

      setSuccess(true);
      setFormData({
        nom: '',
        prenom: '',
        email: '',
        numero_telephone: '',
        role: 'police_municipale',
        zone_intervention: '',
        password: '',
      });

      setTimeout(() => setSuccess(false), 5000);
    } catch (err) {
      console.error('Error creating authority:', err);
      setError(err.message || 'Erreur lors de la création du compte');
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  return (
    <div className="bg-gray-50 min-h-screen p-6">
      {/* Header */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 mb-8">
        <div className="flex items-center gap-4 p-6">
          <UserPlus className="w-10 h-10 text-blue-600" />
          <div className="flex-1">
            <h1 className="text-2xl font-bold text-gray-900">Créer un opérateur</h1>
            <p className="text-gray-600 text-sm mt-1">
              Ajouter un nouveau compte d'opérateur au système
            </p>
          </div>
        </div>
      </div>

      <div className="max-w-2xl">
        {success && (
          <div className="mb-6 bg-white rounded-lg shadow-sm border border-gray-200 p-4" style={{ borderLeft: '4px solid rgb(34, 197, 94)' }}>
            <div className="flex items-start gap-3">
              <CheckCircle className="w-5 h-5 text-green-600 flex-shrink-0 mt-0.5" />
              <div>
                <p className="font-semibold text-gray-900">Compte créé avec succès !</p>
                <p className="text-sm text-gray-600 mt-1">
                  L'opérateur peut maintenant se connecter avec son email et mot de passe.
                </p>
              </div>
            </div>
          </div>
        )}

        {error && (
          <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg flex items-start gap-3">
            <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
            <p className="text-red-700">{error}</p>
          </div>
        )}

        <form onSubmit={handleSubmit} className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div className="space-y-6">
            <div className="grid grid-cols-2 gap-6">
              <div>
                <label htmlFor="prenom" className="block text-sm font-medium text-gray-700 mb-2">
                  Prénom *
                </label>
                <div className="relative">
                  <User className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                  <input
                    id="prenom"
                    name="prenom"
                    type="text"
                    value={formData.prenom}
                    onChange={handleChange}
                    className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    required
                  />
                </div>
              </div>

              <div>
                <label htmlFor="nom" className="block text-sm font-medium text-gray-700 mb-2">
                  Nom *
                </label>
                <div className="relative">
                  <User className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                  <input
                    id="nom"
                    name="nom"
                    type="text"
                    value={formData.nom}
                    onChange={handleChange}
                    className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    required
                  />
                </div>
              </div>
            </div>

            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
                Email *
              </label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  id="email"
                  name="email"
                  type="email"
                  value={formData.email}
                  onChange={handleChange}
                  className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  required
                />
              </div>
            </div>

            <div>
              <label htmlFor="numero_telephone" className="block text-sm font-medium text-gray-700 mb-2">
                Numéro de téléphone *
              </label>
              <div className="relative">
                <Phone className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                <input
                  id="numero_telephone"
                  name="numero_telephone"
                  type="tel"
                  value={formData.numero_telephone}
                  onChange={handleChange}
                  className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  required
                />
              </div>
            </div>

            <div>
              <label htmlFor="role" className="block text-sm font-medium text-gray-700 mb-2">
                Rôle *
              </label>
              <div className="relative">
                <Shield className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
                <select
                  id="role"
                  name="role"
                  value={formData.role}
                  onChange={handleChange}
                  className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent appearance-none bg-white"
                  required
                >
                  {roles.map((role) => (
                    <option key={role.value} value={role.value}>
                      {role.label}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div>
              <label htmlFor="zone_intervention" className="block text-sm font-medium text-gray-700 mb-2">
                Zone d'intervention
              </label>
              <input
                id="zone_intervention"
                name="zone_intervention"
                type="text"
                value={formData.zone_intervention}
                onChange={handleChange}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Ex: Arrondissement 1, Centre-ville, etc."
              />
            </div>

            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-2">
                Mot de passe initial *
              </label>
              <input
                id="password"
                name="password"
                type="password"
                value={formData.password}
                onChange={handleChange}
                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Minimum 6 caractères"
                minLength={6}
                required
              />
              <p className="text-xs text-gray-500 mt-2">
                L'opérateur pourra modifier ce mot de passe après sa première connexion.
              </p>
            </div>
          </div>

          <div className="mt-8 flex gap-4">
            <button
              type="submit"
              disabled={loading}
              className="flex-1 bg-blue-600 text-white py-3 rounded-lg font-semibold hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              <UserPlus className="w-5 h-5" />
              {loading ? 'Création en cours...' : 'Créer le compte'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
