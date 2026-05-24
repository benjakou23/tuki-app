import { Outlet, NavLink } from 'react-router-dom'
import { LayoutDashboard, Users, ShieldCheck, LogOut, Wrench } from 'lucide-react'

const NAV = [
  { to: '/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/verificaciones', icon: ShieldCheck, label: 'Verificaciones' },
  { to: '/usuarios', icon: Users, label: 'Usuarios' },
]

export default function Layout({ onLogout }) {
  return (
    <div className="flex h-screen bg-gray-50">
      <aside className="w-60 bg-gray-900 flex flex-col flex-shrink-0">
        <div className="px-6 py-6 border-b border-white/10">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 bg-orange-500 rounded-lg flex items-center justify-center">
              <Wrench size={16} className="text-white" />
            </div>
            <div>
              <p className="text-white font-semibold text-sm">Chalao</p>
              <p className="text-white/40 text-xs">Panel admin</p>
            </div>
          </div>
        </div>

        <nav className="flex-1 px-3 py-4 space-y-1">
          {NAV.map(function(item) {
            const Icon = item.icon
            return (
              <NavLink
                key={item.to}
                to={item.to}
                className={function(props) {
                  return 'flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all ' +
                    (props.isActive
                      ? 'bg-orange-500 text-white'
                      : 'text-white/60 hover:text-white hover:bg-white/10')
                }}
              >
                <Icon size={18} />
                {item.label}
              </NavLink>
            )
          })}
        </nav>

        <div className="px-3 py-4 border-t border-white/10">
          <button
            onClick={onLogout}
            className="flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium text-white/60 hover:text-white hover:bg-white/10 w-full transition-all"
          >
            <LogOut size={18} />
            Cerrar sesión
          </button>
        </div>
      </aside>

      <main className="flex-1 overflow-auto">
        <Outlet />
      </main>
    </div>
  )
}