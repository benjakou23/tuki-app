import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { ShieldCheck, ShieldX, Clock, FileText, Wrench } from 'lucide-react'
import { useState } from 'react'
import api from '../../lib/api'

const ESTADO_BADGE = {
  docs_enviados: { label: 'Docs enviados', color: 'bg-amber-100 text-amber-700' },
  en_revision: { label: 'En revision', color: 'bg-blue-100 text-blue-700' },
  verificado: { label: 'Verificado', color: 'bg-green-100 text-green-700' },
  rechazado: { label: 'Rechazado', color: 'bg-red-100 text-red-700' },
  sin_verificar: { label: 'Sin verificar', color: 'bg-gray-100 text-gray-600' },
}

const TIPO_DOC = {
  dni_anverso: 'DNI anverso',
  dni_reverso: 'DNI reverso',
  selfie_dni: 'Selfie con DNI',
  certificado: 'Certificado',
  foto_trabajo: 'Foto de trabajo',
  ruc: 'RUC',
}

function UsuarioCard({ u, isActive, onClick }) {
  const badge = ESTADO_BADGE[u.estado_verificacion] || { label: u.estado_verificacion, color: '' }
  const inicial = u.nombre ? u.nombre[0] : '?'
  const esSolicitudEsp = u.motivo_rechazo?.startsWith('SOLICITUD_ESPECIALIDADES:')
  const borderClass = isActive
    ? 'border-2 border-orange-400 bg-orange-50'
    : 'border border-gray-200 hover:border-gray-300'

  return (
    <button
      onClick={onClick}
      className={'w-full text-left bg-white rounded-2xl p-4 transition-all ' + borderClass}
    >
      <div className="flex items-center gap-3 mb-2">
        <div className="w-8 h-8 rounded-full bg-orange-50 flex items-center justify-center text-orange-500 font-semibold text-sm flex-shrink-0">
          {inicial}
        </div>
        <div className="flex-1 min-w-0">
          <p className="font-medium text-sm text-gray-900 truncate">{u.nombre}</p>
          <p className="text-xs text-gray-400">{u.telefono}</p>
        </div>
        {esSolicitudEsp && (
          <span className="text-xs px-2 py-0.5 rounded-full bg-purple-100 text-purple-700 font-medium">
            Especialidades
          </span>
        )}
      </div>
      <div className="flex items-center justify-between">
        <span className={'text-xs px-2 py-0.5 rounded-full font-medium ' + badge.color}>
          {badge.label}
        </span>
        <span className="text-xs text-gray-400 capitalize">{u.rol}</span>
      </div>
    </button>
  )
}

function DocCard({ doc }) {
  const label = TIPO_DOC[doc.tipo] || doc.tipo
  const url = 'http://localhost:8000' + doc.url
  return (
    <a
      href={url}
      target="_blank"
      rel="noreferrer"
      className="flex items-center gap-3 p-3 rounded-xl border border-gray-200 hover:border-orange-400 transition-all"
    >
      <div className="w-8 h-8 bg-gray-100 rounded-lg flex items-center justify-center flex-shrink-0">
        <FileText size={16} className="text-gray-400" />
      </div>
      <div>
        <p className="text-xs font-medium text-gray-800">{label}</p>
        <p className="text-xs text-gray-400">Ver archivo</p>
      </div>
    </a>
  )
}
function DetalleUsuario({ usuario, onAccion, onAprobarEspecialidades, onRechazarEspecialidades, isPending }) {
  const [motivo, setMotivo] = useState('')
  const badge = ESTADO_BADGE[usuario.estado_verificacion] || { label: usuario.estado_verificacion, color: '' }
  const inicial = usuario.nombre ? usuario.nombre[0] : '?'
  const dniInfo = usuario.dni_numero ? ' · DNI: ' + usuario.dni_numero : ''
  const distInfo = usuario.distrito ? ' · ' + usuario.distrito : ''

  const esSolicitudEsp = usuario.motivo_rechazo?.startsWith('SOLICITUD_ESPECIALIDADES:')
  const especialidadesSolicitadas = esSolicitudEsp
    ? usuario.motivo_rechazo.replace('SOLICITUD_ESPECIALIDADES:', '').split(',')
    : []

  return (
    <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
      <div className="p-6 border-b border-gray-100">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-full bg-orange-50 flex items-center justify-center text-orange-500 font-bold text-lg flex-shrink-0">
            {inicial}
          </div>
          <div className="flex-1">
            <h2 className="font-semibold text-gray-900">{usuario.nombre}</h2>
            <p className="text-sm text-gray-400">{usuario.telefono}{dniInfo}{distInfo}</p>
          </div>
          <span className={'text-xs px-3 py-1 rounded-full font-medium capitalize ' + badge.color}>
            {badge.label}
          </span>
        </div>
      </div>

      {/* Solicitud de especialidades */}
      {esSolicitudEsp && (
        <div className="p-6 border-b border-gray-100 bg-purple-50">
          <div className="flex items-center gap-2 mb-3">
            <Wrench size={16} className="text-purple-600" />
            <h3 className="font-medium text-purple-800 text-sm">
              Solicitud de especialidades
            </h3>
          </div>
          <div className="flex flex-wrap gap-2 mb-4">
            {especialidadesSolicitadas.map(function(esp, i) {
              return (
                <span key={i}
                  className="text-xs px-3 py-1.5 bg-white border border-purple-200 text-purple-700 rounded-full font-medium">
                  {esp.trim()}
                </span>
              )
            })}
          </div>
          <div className="flex gap-3">
            <button
              onClick={function() { onAprobarEspecialidades(usuario.id, especialidadesSolicitadas) }}
              disabled={isPending}
              className="flex items-center gap-2 px-4 py-2.5 bg-purple-600 hover:bg-purple-700 text-white rounded-xl text-sm font-medium transition-all disabled:opacity-50"
            >
              <ShieldCheck size={16} />
              Aprobar especialidades
            </button>
            <button
              onClick={function() { onRechazarEspecialidades(usuario.id) }}
              disabled={isPending}
              className="flex items-center gap-2 px-4 py-2.5 bg-gray-200 hover:bg-gray-300 text-gray-700 rounded-xl text-sm font-medium transition-all disabled:opacity-50"
            >
              <ShieldX size={16} />
              Rechazar
            </button>
          </div>
        </div>
      )}

      {/* Documentos */}
      {!esSolicitudEsp && (
        <div className="p-6 border-b border-gray-100">
          <h3 className="font-medium text-gray-800 text-sm mb-4">
            Documentos ({usuario.documentos ? usuario.documentos.length : 0})
          </h3>
          {(!usuario.documentos || usuario.documentos.length === 0) ? (
            <p className="text-sm text-gray-400">Sin documentos aún</p>
          ) : (
            <div className="grid grid-cols-2 gap-3">
              {usuario.documentos.map(function(doc, idx) {
                return <DocCard key={idx} doc={doc} />
              })}
            </div>
          )}
        </div>
      )}

      {/* Acciones verificación normal */}
      {!esSolicitudEsp && (
        <div className="p-6">
          <h3 className="font-medium text-gray-800 text-sm mb-3">Acción</h3>
          <textarea
            value={motivo}
            onChange={function(e) { setMotivo(e.target.value) }}
            placeholder="Motivo (requerido para rechazar o pedir mas docs)"
            rows={2}
            className="w-full px-4 py-3 rounded-xl border border-gray-200 text-sm focus:outline-none focus:border-orange-400 resize-none mb-4"
          />
          <div className="flex gap-3 flex-wrap">
            <button
              onClick={function() { onAccion('aprobar', '') }}
              disabled={isPending}
              className="flex items-center gap-2 px-4 py-2.5 bg-green-500 hover:bg-green-600 text-white rounded-xl text-sm font-medium transition-all disabled:opacity-50"
            >
              <ShieldCheck size={16} />
              Aprobar
            </button>
            <button
              onClick={function() { onAccion('pedir_mas', motivo) }}
              disabled={isPending}
              className="flex items-center gap-2 px-4 py-2.5 bg-amber-400 hover:bg-amber-500 text-white rounded-xl text-sm font-medium transition-all disabled:opacity-50"
            >
              <Clock size={16} />
              Pedir mas docs
            </button>
            <button
              onClick={function() { onAccion('rechazar', motivo) }}
              disabled={isPending}
              className="flex items-center gap-2 px-4 py-2.5 bg-red-500 hover:bg-red-600 text-white rounded-xl text-sm font-medium transition-all disabled:opacity-50"
            >
              <ShieldX size={16} />
              Rechazar
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

export default function VerificacionesPage() {
  const queryClient = useQueryClient()
  const [seleccionado, setSeleccionado] = useState(null)

  const { data: pendientes, isLoading } = useQuery({
    queryKey: ['verificaciones'],
    queryFn: function() {
      return api.get('/admin/verificaciones/pendientes').then(function(r) { return r.data })
    },
  })

  // También cargamos técnicos con solicitudes de especialidades
  const { data: todosUsuarios } = useQuery({
    queryKey: ['usuarios-especialidades'],
    queryFn: function() {
      return api.get('/admin/usuarios').then(function(r) {
        return r.data.filter(function(u) {
          return u.motivo_rechazo?.startsWith('SOLICITUD_ESPECIALIDADES:')
        })
      })
    },
  })

  const mutation = useMutation({
    mutationFn: function(params) {
      return api.post('/admin/verificaciones/' + params.id + '/accion', {
        accion: params.accion,
        motivo: params.motivo,
      })
    },
    onSuccess: function() {
      queryClient.invalidateQueries({ queryKey: ['verificaciones'] })
      queryClient.invalidateQueries({ queryKey: ['usuarios-especialidades'] })
      queryClient.invalidateQueries({ queryKey: ['dashboard'] })
      setSeleccionado(null)
    },
  })

  const mutationEsp = useMutation({
    mutationFn: function(params) {
      return api.post('/admin/especialidades/' + params.id + '/aprobar', {
        especialidades: params.especialidades,
      })
    },
    onSuccess: function() {
      queryClient.invalidateQueries({ queryKey: ['usuarios-especialidades'] })
      setSeleccionado(null)
    },
  })

  function handleAccion(accion, motivo) {
    if (!seleccionado) return
    mutation.mutate({ id: seleccionado.id, accion, motivo })
  }

  function handleAprobarEspecialidades(userId, especialidades) {
    mutationEsp.mutate({ id: userId, especialidades })
  }

  function handleRechazarEspecialidades(userId) {
    api.post('/admin/especialidades/' + userId + '/rechazar').then(function() {
      queryClient.invalidateQueries({ queryKey: ['usuarios-especialidades'] })
      setSeleccionado(null)
    })
  }

  if (isLoading) {
    return <div className="p-8 text-gray-400 text-sm">Cargando...</div>
  }

  const totalVerif = pendientes ? pendientes.length : 0
  const totalEsp = todosUsuarios ? todosUsuarios.length : 0

  return (
    <div className="p-8 flex gap-6 h-screen overflow-hidden">
      <div className="w-80 flex-shrink-0 overflow-auto">
        <h1 className="text-xl font-bold text-gray-900 mb-1">Verificaciones</h1>
        <p className="text-gray-400 text-sm mb-4">
          {totalVerif} identidades · {totalEsp} especialidades
        </p>

        {/* Solicitudes de especialidades */}
        {totalEsp > 0 && (
          <div className="mb-4">
            <p className="text-xs font-semibold text-purple-600 uppercase tracking-wide mb-2 px-1">
              Especialidades pendientes
            </p>
            <div className="space-y-2">
              {todosUsuarios.map(function(u, idx) {
                return (
                  <UsuarioCard
                    key={'esp-' + idx}
                    u={u}
                    isActive={seleccionado && seleccionado.id === u.id}
                    onClick={function() { setSeleccionado(u) }}
                  />
                )
              })}
            </div>
          </div>
        )}

        {/* Verificaciones de identidad */}
        {totalVerif > 0 && (
          <div>
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2 px-1">
              Identidad pendiente
            </p>
            <div className="space-y-2">
              {pendientes.map(function(u, idx) {
                return (
                  <UsuarioCard
                    key={idx}
                    u={u}
                    isActive={seleccionado && seleccionado.id === u.id}
                    onClick={function() { setSeleccionado(u) }}
                  />
                )
              })}
            </div>
          </div>
        )}

        {totalVerif === 0 && totalEsp === 0 && (
          <div className="bg-white rounded-2xl p-6 border border-gray-200 text-center">
            <ShieldCheck size={32} className="text-green-500 mx-auto mb-2" />
            <p className="text-sm text-gray-400">Todo al día</p>
          </div>
        )}
      </div>

      <div className="flex-1 overflow-auto">
        {!seleccionado ? (
          <div className="h-full flex items-center justify-center">
            <div className="text-center">
              <FileText size={48} className="text-gray-200 mx-auto mb-3" />
              <p className="text-gray-400 text-sm">Selecciona un usuario para revisar</p>
            </div>
          </div>
        ) : (
          <DetalleUsuario
            usuario={seleccionado}
            onAccion={handleAccion}
            onAprobarEspecialidades={handleAprobarEspecialidades}
            onRechazarEspecialidades={handleRechazarEspecialidades}
            isPending={mutation.isPending || mutationEsp.isPending}
          />
        )}
      </div>
    </div>
  )
}