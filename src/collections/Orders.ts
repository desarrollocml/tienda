// src/collections/Orders.ts
import type { CollectionConfig } from 'payload'
import type { User } from '../payload-types' // Importa User para tipar el acceso

// --- Función Auxiliar para Acceso - Cualquier Usuario Autenticado ---
// (Misma función que usamos en ManualOrders)
const isAuthenticated = ({ req: { user } }: { req: { user?: User | null } }): boolean => {
  return Boolean(user)
}

// --- Definición de la Colección Orders (para pedidos del Frontend) ---
export const Orders: CollectionConfig = {
  slug: 'orders', // Slug para la API: /api/orders
  admin: {
    useAsTitle: 'customerName', // Mostrar nombre del cliente o ID si falta nombre
    defaultColumns: ['id', 'customerName', 'totalAmount', 'status', 'createdAt'],
    listSearchableFields: ['customerName', 'customerEmail', 'id'],
    group: 'Tienda Online', // Agrupar en la barra lateral
    description: 'Pedidos recibidos desde el sitio web.',
  },
  access: {
    // --- IMPORTANTE: Permite creación pública desde el frontend ---
    create: () => true,
    // -----------------------------------------------------------
    // Solo usuarios autenticados pueden leer, actualizar y borrar
    read: isAuthenticated,
    update: isAuthenticated,
    delete: isAuthenticated, // Considera restringir más si es necesario
  },
  timestamps: true, // Añadir createdAt y updatedAt
  fields: [
    // --- Datos del Cliente (Enviados desde el frontend) ---
    // Hacemos estos campos editables inicialmente por si hay errores al crear
    {
      name: 'customerName',
      label: 'Nombre del Cliente',
      type: 'text',
      required: true,
      // admin: { readOnly: true } // Quitamos readOnly para permitir edición inicial
    },
    {
      name: 'customerEmail',
      label: 'Email del Cliente',
      type: 'email',
      required: true,
      // admin: { readOnly: true }
    },
    {
      name: 'customerPhone',
      label: 'Teléfono del Cliente',
      type: 'text',
      // admin: { readOnly: true }
    },

    // --- Productos Ordenados (Vinculados y con Snapshot) ---
    // Guardamos la relación Y una "foto" de los detalles al momento del pedido
    {
      name: 'orderedProducts',
      label: 'Productos Ordenados',
      type: 'array',
      required: true,
      minRows: 1,
      // Los items individuales serán editables (ej: cantidad si hubo error)
      // admin: { readOnly: true }, // Quitamos readOnly del array general
      labels: {
        singular: 'Producto Ordenado',
        plural: 'Productos Ordenados',
      },
      fields: [
        // {
        //   name: 'product',
        //   label: 'Producto (Relación)',
        //   type: 'relationship',
        //   relationTo: ['products'], // Correcto para MongoDB y v3
        //   required: true,
        //   // admin: { readOnly: true } // Permitir ver/cambiar relación si es necesario
        // },
        {
          name: 'nameSnapshot', // Nombre en el momento del pedido
          label: 'Nombre (Snapshot)',
          type: 'text',
          required: true,
          admin: { readOnly: true, description: 'Nombre del producto al momento de la orden.' },
        },
        {
          name: 'priceSnapshot', // Precio unitario en el momento del pedido
          label: 'Precio Unitario (Snapshot)',
          type: 'number',
          required: true,
          admin: { readOnly: true, description: 'Precio unitario al momento de la orden.' },
        },
        {
          name: 'quantity', // Cantidad ordenada (editable si es necesario)
          label: 'Cantidad',
          type: 'number',
          required: true,
          min: 1,
          // admin: { readOnly: true } // Permitir edición
        },
      ],
    },

    // --- Total y Estado ---
    {
      name: 'totalAmount',
      label: 'Monto Total',
      type: 'number',
      required: true,
      min: 0,
      // admin: { readOnly: true } // Permitir edición si es necesario ajustar
    },
    {
      name: 'status',
      label: 'Estado del Pedido',
      type: 'select',
      required: true,
      // Usamos los mismos estados que ManualOrders para consistencia
      defaultValue: 'recibido', // Puede ser 'recibido' o 'pending'
      options: [
        { label: 'Recibido', value: 'recibido' }, // O 'Pendiente' / 'pending'
        { label: 'En Proceso', value: 'en_proceso' },
        { label: 'Entregado', value: 'entregado' }, // O 'Enviado', 'Completado' etc.
        { label: 'Cancelado', value: 'cancelado' }, // Añadir Cancelado puede ser útil
      ],
      access: {
        // Cualquiera autenticado puede actualizar el estado
        update: isAuthenticated,
      },
      admin: {
        readOnly: false, // El estado SIEMPRE debe ser editable
        position: 'sidebar',
      },
    },
    {
      name: 'adminNotes', // Igual que en ManualOrders
      label: 'Notas Internas (Admin)',
      type: 'textarea',
      admin: {
        description: 'Notas privadas para seguimiento interno.',
      },
    },
  ],
}
