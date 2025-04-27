// src/collections/Products.ts
import type { CollectionConfig } from 'payload'

export const Products: CollectionConfig = {
  slug: 'products', // Coincide con la URL de la API '/api/products'
  admin: {
    useAsTitle: 'name', // Usa el campo 'name' como título en el admin
    description: 'Productos disponibles en la tienda online.',
  },
  access: {
    // Permite que cualquiera lea la lista de productos y productos individuales
    read: () => true,
    // Podrías restringir create, update, delete a usuarios autenticados (admins)
    // create: ({ req: { user } }) => user?.role === 'admin', // Ejemplo
    // update: ({ req: { user } }) => user?.role === 'admin', // Ejemplo
    // delete: ({ req: { user } }) => user?.role === 'admin', // Ejemplo
  },
  fields: [
    {
      name: 'name',
      label: 'Nombre del Producto',
      type: 'text',
      required: true, // El nombre es esencial
    },
    {
      name: 'description',
      label: 'Descripción',
      type: 'textarea', // 'textarea' es bueno para descripciones más largas. 'richText' si necesitas formato.
      // Si usaras 'richText', tu frontend necesitaría renderizar HTML de forma segura.
    },
    {
      name: 'price',
      label: 'Precio',
      type: 'number',
      required: true, // El precio es esencial
      min: 0, // Evita precios negativos
      admin: {
        // Ayuda visual en el admin
        step: 0.01,
      },
    },
    {
      name: 'productImage', // Coincide con product.productImage.url en el frontend
      label: 'Imagen del Producto',
      type: 'upload', // Tipo de campo para archivos/imágenes
      relationTo: 'media', // IMPORTANTE: Debe coincidir con el slug de tu colección Media
      required: true, // Probablemente quieras que todos los productos tengan imagen
      admin: {
        description: 'Sube la imagen principal del producto.',
      },
    },
    // --- Campos Opcionales (Podrías añadir más adelante) ---
    // {
    //   name: 'sku',
    //   label: 'SKU (Código de Artículo)',
    //   type: 'text',
    //   unique: true,
    // },
    {
      name: 'stock',
      label: 'Cantidad en Stock',
      type: 'number',
      min: 0,
      defaultValue: 0,
    },
    // {
    //   name: 'category',
    //   label: 'Categoría',
    //   type: 'relationship',
    //   relationTo: 'categories', // Necesitarías una colección 'Categories'
    //   hasMany: false, // o true si un producto puede tener varias categorías
    // }
  ],
}
