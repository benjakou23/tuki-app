import { useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { ShieldCheck, User, Wrench } from 'lucide-react'
import api from '../../lib/api'

const estadoColor = {
  verificado: 'bg-teal-50 text-teal-600',
  sin_verificar: 'bg-gris-100 text-gris-600',
  docs_enviados: 'bg-amber-100 text-amber-700',
  rechazado: 'bg-coral-50 text-coral-600',
  suspendido: 'bg-red-100 text-red-600',
}

export default function UsuariosPage() {
  const [rol, setRol] = useState('')
  const [estado, setEstado] = useState('')

  const { data: usuarios, isLoading } = useQuery({
    queryKey: ['usuarios', rol, estado],
    queryFn: () => {
      const params = new URLSearchParams()
      if (rol) params.append('rol', rol)
      if (estado) params.append('estado', estado)
      return api.get(`/admin/usuarios?${params}`).then(r => r.data)
    },
  })

  return (
    <div className="p-8">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-carbon">Usuarios</h1>
        <p className="text-gris-400 text-sm mt-1">
          {usuarios?.length ?? 0} usuarios registrados
        </p>
      </div>

      {/* Filtros */}
      <div className="flex gap-3 mb-6">
        <select
          value={rol}
          onChange={e => setRol(e.target.value)}
          className="px-4 py-2.5 rounded-xl border border-gris-200 text-sm focus:outline-none focus:border-coral-400 bg-white"
        >
          <option value="">Todos los roles</option>
          <option value="cliente">Clientes</option>
          <option value="tecnico">Técnicos</option>
          <option value="admin">Admins</option>
        </select>
        <select
          value={estado}
          onChange={e => setEstado(e.target.value)}
          className="px-4 py-2.5 rounded-xl border border-gris-200 text-sm focus:outline-none focus:border-coral-400 bg-white"
        >
          <option value="">Todos los estados</option>
          <option value="verificado">Verificados</option>
          <option value="sin_verificar">Sin verificar</option>
          <option value="docs_enviados">Docs enviados</option>
          <option value="rechazado">Rechazados</option>
          <option value="suspendido">Suspendidos</option>
        </select>
      </div>

      {/* Tabla */}
      {isLoading ? (
        <p className="text-gris-400 text-sm">Cargando...</p>
      ) : (
        <div className="bg-white rounded-2xl border border-gris-200/60 overflow-hidden">
          <table className="w-full">
            <thead>
              <tr className="border-b border-gris-100">
                <th className="text-left px-6 py-4 text-xs font-medium text-gris-400 uppercase tracking-wide">Usuario</th>
                <th className="text-left px-6 py-4 text-xs font-medium text-gris-400 uppercase tracking-wide">Contacto</th>
                <th className="text-left px-6 py-4 text-xs font-medium text-gris-400 uppercase tracking-wide">Rol</th>
                <th className="text-left px-6 py-4 text-xs font-medium text-gris-400 uppercase tracking-wide">Estado</th>
                <th className="text-left px-6 py-4 text-xs font-medium text-gris-400 uppercase tracking-wide">Registro</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gris-100">
              {usuarios?.map(u => (
                <tr key={u.id} className="hover:bg-gris-100/30 transition-colors">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-coral-50 flex items-center justify-center text-coral-400 font-semibold text-sm">
                        {u.nombre[0]}
                      </div>
                      <div>
                        <p className="font-medium text-sm text-carbon">{u.nombre}</p>
                        <p className="text-xs text-gris-400">DNI: {u.dni_numero ?? '—'}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <p className="text-sm text-carbon">{u.telefono}</p>
                    <p className="text-xs text-gris-400">{u.email ?? '—'}</p>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-1.5">
                      {u.rol === 'tecnico'
                        ? <Wrench size={14} className="text-teal-400" />
                        : <User size={14} className="text-gris-400" />}
                      <span className="text-sm text-carbon capitalize">{u.rol}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${estadoColor[u.estado_verificacion]}`}>
                      {u.estado_verificacion?.replace('_', ' ')}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <p className="text-xs text-gris-400">
                      {new Date(u.creado_en).toLocaleDateString('es-PE')}
                    </p>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {usuarios?.length === 0 && (
            <div className="text-center py-12 text-gris-400 text-sm">
              No hay usuarios con estos filtros
            </div>
          )}
        </div>
      )}
    </div>
  )
}