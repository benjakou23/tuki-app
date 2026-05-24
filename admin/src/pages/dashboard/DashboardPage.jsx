import { useQuery } from '@tanstack/react-query'
import { Users, ShieldCheck, Wrench, ClipboardList, Clock } from 'lucide-react'
import api from '../../lib/api'

const StatCard = ({ icon: Icon, label, value, color }) => (
  <div className="bg-white rounded-2xl p-6 border border-gris-200/60">
    <div className={`w-10 h-10 rounded-xl flex items-center justify-center mb-4 ${color}`}>
      <Icon size={20} className="text-white" />
    </div>
    <p className="text-2xl font-bold text-carbon">{value ?? '—'}</p>
    <p className="text-sm text-gris-400 mt-1">{label}</p>
  </div>
)

export default function DashboardPage() {
  const { data, isLoading } = useQuery({
    queryKey: ['dashboard'],
    queryFn: () => api.get('/admin/dashboard').then(r => r.data),
    refetchInterval: 30000,
  })

  return (
    <div className="p-8">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-carbon">Dashboard</h1>
        <p className="text-gris-400 text-sm mt-1">
          Resumen general de Chalao
        </p>
      </div>

      {/* Stats */}
      {isLoading ? (
        <div className="text-gris-400 text-sm">Cargando...</div>
      ) : (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          <StatCard
            icon={Users}
            label="Total usuarios"
            value={data?.total_usuarios}
            color="bg-coral-400"
          />
          <StatCard
            icon={Wrench}
            label="Técnicos activos"
            value={data?.total_tecnicos}
            color="bg-teal-400"
          />
          <StatCard
            icon={Clock}
            label="Pendientes verificación"
            value={data?.pendientes_verificacion}
            color="bg-amber-400"
          />
          <StatCard
            icon={ClipboardList}
            label="Total pedidos"
            value={data?.total_pedidos}
            color="bg-carbon"
          />
        </div>
      )}

      {/* Info cards */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div className="bg-white rounded-2xl p-6 border border-gris-200/60">
          <h2 className="font-semibold text-carbon mb-1">Verificaciones</h2>
          <p className="text-sm text-gris-400 mb-4">
            Usuarios esperando revisión de documentos
          </p>
          <div className="flex items-center gap-3">
            <div className="flex-1 bg-gris-100 rounded-full h-2">
              <div
                className="bg-coral-400 h-2 rounded-full transition-all"
                style={{
                  width: data?.total_usuarios
                    ? `${(data.pendientes_verificacion / data.total_usuarios) * 100}%`
                    : '0%'
                }}
              />
            </div>
            <span className="text-xs font-medium text-gris-600">
              {data?.pendientes_verificacion ?? 0} pendientes
            </span>
          </div>
        </div>

        <div className="bg-white rounded-2xl p-6 border border-gris-200/60">
          <h2 className="font-semibold text-carbon mb-1">Usuarios verificados</h2>
          <p className="text-sm text-gris-400 mb-4">
            Con badge de confianza activo
          </p>
          <div className="flex items-center gap-3">
            <div className="flex-1 bg-gris-100 rounded-full h-2">
              <div
                className="bg-teal-400 h-2 rounded-full transition-all"
                style={{
                  width: data?.total_usuarios
                    ? `${(data.usuarios_verificados / data.total_usuarios) * 100}%`
                    : '0%'
                }}
              />
            </div>
            <span className="text-xs font-medium text-gris-600">
              {data?.usuarios_verificados ?? 0} verificados
            </span>
          </div>
        </div>
      </div>
    </div>
  )
}