<script setup lang="ts">
import { Head, Link } from '@inertiajs/vue3';
</script>

<template>
    <Head title="Privacy Policy" />
    <div class="min-h-screen bg-white dark:bg-gray-900">
        <!-- Navigation -->
        <nav class="container mx-auto px-6 py-6">
            <div class="flex items-center justify-between">
                <Link href="/" class="flex items-center gap-3">
                    <img src="/app-icon.png" alt="Focus Totem" class="w-12 h-12 rounded-xl shadow-lg" />
                    <span class="text-2xl font-bold text-gray-900 dark:text-white">Focus Totem</span>
                </Link>
                <Link
                    href="/"
                    class="px-6 py-2 text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white transition-colors"
                >
                    Back to Home
                </Link>
            </div>
        </nav>

        <!-- Privacy Policy Content -->
        <main class="container mx-auto px-6 py-16">
            <div class="max-w-4xl mx-auto bg-white dark:bg-gray-800 rounded-3xl p-12 shadow-2xl">
                <h1 class="text-4xl md:text-5xl font-bold text-gray-900 dark:text-white mb-8">
                    Privacy Policy
                </h1>

                <div class="space-y-8 text-gray-700 dark:text-gray-300">
                    <section>
                        <p class="text-sm text-gray-600 dark:text-gray-400 mb-6">
                            Last Updated: December 24, 2024
                        </p>
                        <p class="text-lg leading-relaxed">
                            Focus Totem is committed to protecting your privacy. This Privacy Policy explains our practices regarding the collection, use, and disclosure of information when you use our application.
                        </p>
                    </section>

                    <section>
                        <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-4">
                            Information Collection and Use
                        </h2>
                        <p class="leading-relaxed">
                            <strong>We do not collect, store, or transmit any personal information or user data.</strong> Focus Totem operates entirely locally on your device. All visual recognition processing occurs on your Mac, and no data is sent to external servers.
                        </p>
                    </section>

                    <section>
                        <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-4">
                            Camera Access
                        </h2>
                        <p class="leading-relaxed">
                            Focus Totem requires access to your device's camera to detect your chosen totem object. All camera data is processed locally on your device in real-time and is not recorded, saved, or transmitted in any way. No images or video are stored or shared.
                        </p>
                    </section>

                    <section>
                        <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-4">
                            Local Data Storage
                        </h2>
                        <p class="leading-relaxed">
                            The application stores your totem configuration and website blocking preferences locally on your device. This data remains on your device and is never transmitted to us or any third parties.
                        </p>
                    </section>

                    <section>
                        <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-4">
                            Third-Party Services
                        </h2>
                        <p class="leading-relaxed">
                            Focus Totem does not integrate with or share data with any third-party services, analytics platforms, or advertising networks.
                        </p>
                    </section>

                    <section>
                        <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-4">
                            Data Security
                        </h2>
                        <p class="leading-relaxed">
                            Since we do not collect or transmit any user data, there is no risk of data breaches or unauthorized access to your information through our services. All data remains securely on your local device under your control.
                        </p>
                    </section>

                    <section>
                        <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-4">
                            Children's Privacy
                        </h2>
                        <p class="leading-relaxed">
                            Our application does not knowingly collect any information from anyone, including children under the age of 13. The application is designed to operate entirely locally without any data collection.
                        </p>
                    </section>

                    <section>
                        <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-4">
                            Changes to This Privacy Policy
                        </h2>
                        <p class="leading-relaxed">
                            We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date at the top of this policy.
                        </p>
                    </section>

                    <section>
                        <h2 class="text-2xl font-bold text-gray-900 dark:text-white mb-4">
                            Contact Us
                        </h2>
                        <p class="leading-relaxed">
                            If you have any questions or concerns about this Privacy Policy, please contact us through the application's support channels.
                        </p>
                    </section>

                    <section class="pt-8 border-t border-gray-200 dark:border-gray-700">
                        <p class="text-lg font-semibold text-gray-900 dark:text-white">
                            Summary
                        </p>
                        <p class="leading-relaxed mt-2">
                            Focus Totem is a privacy-first application. We do not collect, store, or share any of your personal information or usage data. Your privacy is fully protected as all processing occurs locally on your device.
                        </p>
                    </section>
                </div>
            </div>
        </main>

        <!-- Footer -->
        <footer class="container mx-auto px-6 py-8 border-t border-gray-200 dark:border-gray-700">
            <div class="flex flex-col md:flex-row justify-between items-center gap-4">
                <div class="text-gray-600 dark:text-gray-400">
                    © 2026 Focus Totem. All rights reserved.
                </div>
                <div class="flex gap-6">
                    <Link href="/" class="text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors">
                        Home
                    </Link>
                </div>
            </div>
        </footer>
    </div>
</template>
