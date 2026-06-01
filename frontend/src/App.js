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

            <Route path="/worker" element={
              <ProtectedRoute role="worker"><WorkerLayout><WorkerDashboard /></WorkerLayout></ProtectedRoute>
            } />
            <Route path="/worker/history" element={
              <ProtectedRoute role="worker"><WorkerLayout><WorkerHistory /></WorkerLayout></ProtectedRoute>
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
