import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { AutoriteDashboardLayout } from './components/AutoriteDashboardLayout';
import { DashboardLayout } from './components/DashboardLayout';
import { ProtectedRoute } from './components/ProtectedRoute';
import { AuthProvider } from './contexts/AuthContext';
import { AgentLayout } from './layouts/AgentLayout';
import { ActivityLogsPage } from './pages/ActivityLogsPage';
import { AdminManagementPage } from './pages/AdminManagementPage';
import { AdminProfilePage } from './pages/AdminProfilePage';
import { AuditPage } from './pages/AuditPage';
import { CreateAuthorityPage } from './pages/CreateAuthorityPage';
import { DashboardPage } from './pages/DashboardPage';
import { LoginPage } from './pages/LoginPage';
import { NotificationsPage } from './pages/NotificationsPage';
import { SignalementsMapPage } from './pages/SignalementsMapPage';
import { StatisticsPage } from './pages/StatisticsPage';
import { UsersPage } from './pages/UsersPage';
// Pages Autorité
import { AgentsManagementPage } from './pages/autorite/AgentsManagementPage';
import { AutoriteDashboardPage } from './pages/autorite/AutoriteDashboardPage';
import { AutoriteLocalisationPage } from './pages/autorite/AutoriteLocalisationPage';
import { AutoriteReportsPage } from './pages/autorite/AutoriteReportsPage';
import { AutoriteSignalementsPage } from './pages/autorite/AutoriteSignalementsPage';
// Pages Agent
import { AgentDashboardPage } from './pages/agent/AgentDashboardPage';
import { AgentMapPage } from './pages/agent/AgentMapPage';
import { AgentPerformancePage } from './pages/agent/AgentPerformancePage';
import { AgentProfilePage } from './pages/agent/AgentProfilePage';
import { AgentReportsPage } from './pages/agent/AgentReportsPage';
import { DebugPage } from './pages/agent/DebugPage';

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          {/* Routes SUPER ADMIN */}
          <Route
            path="/dashboard"
            element={
              <ProtectedRoute requiredRole="admin">
                <DashboardLayout />
              </ProtectedRoute>
            }
          >
            <Route index element={<DashboardPage />} />
            <Route path="users" element={<UsersPage />} />
            <Route path="logs" element={<ActivityLogsPage />} />
            <Route path="admins" element={<AdminManagementPage />} />
            <Route path="audit" element={<AuditPage />} />
            <Route path="create-authority" element={<CreateAuthorityPage />} />
            <Route path="notifications" element={<NotificationsPage />} />
            <Route path="signalements" element={<SignalementsMapPage />} />
            <Route path="statistics" element={<StatisticsPage />} />
            <Route path="profile" element={<AdminProfilePage />} />
          </Route>

          {/* Routes AUTORITÉ */}
          <Route
            path="/autorite"
            element={
              <ProtectedRoute requiredRole="autorite">
                <AutoriteDashboardLayout />
              </ProtectedRoute>
            }
          >
            <Route index element={<AutoriteDashboardPage />} />
            <Route path="signalements" element={<AutoriteSignalementsPage />} />
            <Route path="localisation" element={<AutoriteLocalisationPage />} />
            <Route path="rapports" element={<AutoriteReportsPage />} />
            <Route path="statistiques" element={<StatisticsPage />} />
            <Route path="profil" element={<AdminProfilePage />} />
          </Route>

          {/* Routes AGENT */}
          <Route
            path="/agent"
            element={
              <ProtectedRoute requiredRole="agent">
                <AgentLayout />
              </ProtectedRoute>
            }
          >
            <Route index element={<Navigate to="/agent/dashboard" replace />} />
            <Route path="dashboard" element={<AgentDashboardPage />} />
            <Route path="map" element={<AgentMapPage />} />
            <Route path="reports" element={<AgentReportsPage />} />
            <Route path="performance" element={<AgentPerformancePage />} />
            <Route path="profile" element={<AgentProfilePage />} />
            <Route path="debug" element={<DebugPage />} />
          </Route>

          <Route path="/" element={<Navigate to="/login" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}

export default App;
