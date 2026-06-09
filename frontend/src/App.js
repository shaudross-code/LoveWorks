import "@/App.css";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { Toaster } from "@/components/ui/sonner";
import { AuthProvider, useAuth } from "@/context/AuthContext";
import ProtectedRoute from "@/components/ProtectedRoute";
import AdminLayout from "@/components/AdminLayout";
import WorkerLayout from "@/components/WorkerLayout";

import Login from "@/pages/Login";
import AdminDashboard from "@/pages/AdminDashboard";
import AdminWorkers from "@/pages/AdminWorkers";
import AdminTasks from "@/pages/AdminTasks";
import AdminPayroll from "@/pages/AdminPayroll";
import Profile from "@/pages/Profile";
import AdminGoals from "@/pages/AdminGoals";
import AdminTrips from "@/pages/AdminTrips";
import AdminEssentials from "@/pages/AdminEssentials";
import Awards from "@/pages/Awards";
import Announcements from "@/pages/Announcements";
import WorkerDashboard from "@/pages/WorkerDashboard";
import WorkerHistory from "@/pages/WorkerHistory";

function RootRedirect() {
  const { user } = useAuth();
  if (user === null) return null;
  if (user === false) return <Navigate to="/login" replace />;
  return <Navigate to={user.role === "admin" ? "/admin" : "/worker"} replace />;
}

function App() {
  return (
    <div className="App">
      <AuthProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/" element={<RootRedirect />} />
            <Route path="/login" element={<Login />} />

            <Route path="/admin" element={
              <ProtectedRoute role="admin"><AdminLayout><AdminDashboard /></AdminLayout></ProtectedRoute>
            } />
            <Route path="/admin/workers" element={
              <ProtectedRoute role="admin"><AdminLayout><AdminWorkers /></AdminLayout></ProtectedRoute>
            } />
            <Route path="/admin/tasks" element={
              <ProtectedRoute role="admin"><AdminLayout><AdminTasks /></AdminLayout></ProtectedRoute>
            } />
            <Route path="/admin/payroll" element={
              <ProtectedRoute role="admin"><AdminLayout><AdminPayroll /></AdminLayout></ProtectedRoute>
            } />
            <Route path="/admin/goals" element={
              <ProtectedRoute role="admin"><AdminLayout><AdminGoals /></AdminLayout></ProtectedRoute>
            } />
            <Route path="/admin/trips" element={
              <ProtectedRoute role="admin"><AdminLayout><AdminTrips /></AdminLayout></ProtectedRoute>
            } />
            <Route path="/admin/essentials" element={
              <ProtectedRoute role="admin"><AdminLayout><AdminEssentials /></AdminLayout></ProtectedRoute>
            } />
            <Route path="/admin/announcements" element={
              <ProtectedRoute role="admin"><AdminLayout><Announcements /></AdminLayout></ProtectedRoute>
            } />

            <Route path="/worker" element={
              <ProtectedRoute role="worker"><WorkerLayout><WorkerDashboard /></WorkerLayout></ProtectedRoute>
            } />
            <Route path="/worker/history" element={
              <ProtectedRoute role="worker"><WorkerLayout><WorkerHistory /></WorkerLayout></ProtectedRoute>
            } />
            <Route path="/worker/awards" element={
              <ProtectedRoute role="worker"><WorkerLayout><Awards /></WorkerLayout></ProtectedRoute>
            } />
            <Route path="/worker/announcements" element={
              <ProtectedRoute role="worker"><WorkerLayout><Announcements /></WorkerLayout></ProtectedRoute>
            } />
            <Route path="/worker/essentials" element={
              <ProtectedRoute role="worker"><WorkerLayout><AdminEssentials /></WorkerLayout></ProtectedRoute>
            } />
            <Route path="/worker/trips" element={
              <ProtectedRoute role="worker"><WorkerLayout><AdminTrips /></WorkerLayout></ProtectedRoute>
            } />
            <Route path="/worker/profile" element={
              <ProtectedRoute role="worker"><WorkerLayout><Profile /></WorkerLayout></ProtectedRoute>
            } />
            <Route path="/admin/profile" element={
              <ProtectedRoute role="admin"><AdminLayout><Profile /></AdminLayout></ProtectedRoute>
            } />

            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </BrowserRouter>
        <Toaster richColors closeButton position="top-right" theme="dark" />
      </AuthProvider>
    </div>
  );
}

export default App;
