import { useState } from 'react'
import { Wrench } from 'lucide-react'
import api from '../../lib/api'

export default function LoginPage({ onLogin }) {
  const [telefono, setTelefono] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [cargando, setCargando] = useState(false)

  function handleSubmit(e) {
    e.preventDefault()
    setCargando(true)
    setError('')

    api.post('/usuarios/login', { telefono: telefono, password: password })
      .then(function(res) {
        const data = res.data
        if (data.usuario.rol !== 'admin') {
          setError('No tienes permisos de administrador')
          setCargando(false)
          return
        }
        localStorage.setItem('admin_token', data.access_token)
        localStorage.setItem('admin_user', JSON.stringify(data.usuario))
        onLogin()
      })
      .catch(function() {
        setError('Credenciales incorrectas')
        setCargando(false)
      })
  }

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-6">
      <div className="w-full max-w-sm">
        <div className="flex items-center gap-3 mb-10">
          <div className="w-10 h-10 bg-orange-500 rounded-xl flex items-center justify-center">
            <Wrench size={20} className="text-white" />
          </div>
          <div>
            <p className="font-bold text-gray-900 text-xl">Chalao</p>
            <p className="text-gray-400 text-xs">Panel de administración</p>
          </div>
        </div>

        <div className="bg-white rounded-2xl p-8 border border-gray-200">
          <h1 className="text-xl font-semibold text-gray-900 mb-1">Bienvenido</h1>
          <p className="text-gray-400 text-sm mb-6">Ingresa con tu cuenta de administrador</p>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="text-xs font-medium text-gray-600 mb-1.5 block">
                Número de celular
              </label>
              <input
                type="tel"
                value={telefono}
                onChange={function(e) { setTelefono(e.target.value) }}
                placeholder="9XXXXXXXX"
                className="w-full px-4 py-3 rounded-xl border border-gray-200 text-sm focus:outline-none focus:border-orange-400 transition-all"
              />
            </div>

            <div>
              <label className="text-xs font-medium text-gray-600 mb-1.5 block">
                Contraseña
              </label>
              <input
                type="password"
                value={password}
                onChange={function(e) { setPassword(e.target.value) }}
                placeholder="••••••••"
                className="w-full px-4 py-3 rounded-xl border border-gray-200 text-sm focus:outline-none focus:border-orange-400 transition-all"
              />
            </div>

            {error && (
              <div className="bg-red-50 text-red-600 text-sm px-4 py-3 rounded-xl">
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={cargando}
              className="w-full bg-orange-500 hover:bg-orange-600 text-white font-semibold py-3 rounded-xl transition-all disabled:opacity-50"
            >
              {cargando ? 'Ingresando...' : 'Ingresar'}
            </button>
          </form>
        </div>

        <p className="text-center text-gray-400 text-xs mt-6">Chalao, y listo.</p>
      </div>
    </div>
  )
}