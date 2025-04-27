// src/collections/ManualOrders.ts (VERSIÓN MÍNIMA DE PRUEBA)
import type { CollectionConfig } from 'payload'

export const ManualOrders: CollectionConfig = {
  slug: 'manual-orders',
  admin: {
    useAsTitle: 'tempTitle', // Usar un campo simple como título
  },
  access: {
    // Acceso mínimo para probar
    read: () => true,
    create: () => true,
  },
  fields: [
    {
      name: 'tempTitle', // Un campo simple para usar como título
      label: 'Título Temporal',
      type: 'text',
      required: true,
    },
    {
      name: 'someData', // Otro campo simple
      label: 'Datos de Prueba',
      type: 'text',
    },
  ],
}
