import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { useState } from 'react'
import LoginPage from './pages/auth/LoginPage'
import DashboardPage from './pages/dashboard/DashboardPage'
import VerificacionesPage from './pages/verificaciones/VerificacionesPage'
import UsuariosPage from './pages/usuarios/UsuariosPage'
import Layout from './components/Layout'

const queryClient = new QueryClient()

export default function App() {
  const [autenticado, setAutenticado] = useState(
    function() { return !!localStorage.getItem('admin_token') }
  )

  function onLogin() {
    setAutenticado(true)
  }

  function onLogout() {
    localStorage.removeItem('admin_token')
    localStorage.removeItem('admin_user')
    setAutenticado(false)
  }

  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          <Route
            path="/login"
            element={autenticado ? <Navigate to="/dashboard" /> : <LoginPage onLogin={onLogin} />}
          />
          <Route
            path="/"
            element={autenticado ? <Layout onLogout={onLogout} /> : <Navigate to="/login" />}
          >
            <Route index element={<Navigate to="/dashboard" />} />
            <Route path="dashboard" element={<DashboardPage />} />
            <Route path="verificaciones" element={<VerificacionesPage />} />
            <Route path="usuarios" element={<UsuariosPage />} />
          </Route>
          <Route path="*" element={<Navigate to={autenticado ? '/dashboard' : '/login'} />} />
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  )
}