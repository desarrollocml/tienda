import { withPayload } from '@payloadcms/next/withPayload'

/** @type {import('next').NextConfig} */
const nextConfig = {
  // Your Next.js config here
  devIndicators: false,
  output: 'standalone',
}

export default withPayload(nextConfig, { devBundleServerPackages: false })
