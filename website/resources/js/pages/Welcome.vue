<script setup lang="ts">
import { Head } from '@inertiajs/vue3';
</script>

<template>
    <Head title="Welcome" />
    <div class="min-h-screen bg-white dark:bg-gray-900">
        <!-- Navigation -->
        <!--
        <nav class="container mx-auto px-6 py-6">
            <div class="flex items-center justify-center">
                <div class="flex items-center gap-3">
                    <img src="/app-icon.png" alt="Focus Totem" class="w-12 h-12 rounded-xl shadow-lg" />
                    <span class="text-2xl font-bold text-gray-900 dark:text-white">Focus Totem</span>
                </div>
            </div>
        </nav>
        -->

        <!-- Hero Section -->
        <main class="container mx-auto px-6 py-16">
            <div class="max-w-5xl mx-auto">
                <!-- Main Content -->
                <div class="text-center mb-16">
                    <div class="flex justify-center mb-8">
                        <img src="/app-icon.png" alt="Focus Totem App Icon" class="w-32 h-32 md:w-40 md:h-40 rounded-3xl shadow-2xl" />
                    </div>
                    <h1 class="text-5xl md:text-7xl font-bold text-gray-900 dark:text-white mb-6">
                        Stay Focused with<br />
                        <span class="text-blue-600 dark:text-blue-400">Focus Totem</span>
                    </h1>
                    <p class="text-xl md:text-2xl text-gray-700 dark:text-gray-300 mb-8 max-w-3xl mx-auto">
                        An iPhone app that helps you maintain focus by requiring a physical object (your "totem") to be present on your desk
                    </p>
                </div>

                <!-- Features Grid -->
                <div class="grid md:grid-cols-3 gap-8 mb-16">
                    <div class="bg-gray-50 dark:bg-gray-800 rounded-2xl p-8 shadow-xl hover:shadow-2xl transition-shadow">
                        <div class="w-16 h-16 bg-blue-100 dark:bg-blue-900 rounded-xl flex items-center justify-center mb-6">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-blue-600 dark:text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                            </svg>
                        </div>
                        <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-3">Visual Detection</h3>
                        <p class="text-gray-600 dark:text-gray-400">
                            Uses your iPhone's camera to detect your chosen totem object in real-time
                        </p>
                    </div>

                    <div class="bg-gray-50 dark:bg-gray-800 rounded-2xl p-8 shadow-xl hover:shadow-2xl transition-shadow">
                        <div class="w-16 h-16 bg-blue-100 dark:bg-blue-900 rounded-xl flex items-center justify-center mb-6">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-blue-600 dark:text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                            </svg>
                        </div>
                        <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-3">Smart Blocking</h3>
                        <p class="text-gray-600 dark:text-gray-400">
                            Automatically blocks distracting websites when your totem is not detected
                        </p>
                    </div>

                    <div class="bg-gray-50 dark:bg-gray-800 rounded-2xl p-8 shadow-xl hover:shadow-2xl transition-shadow">
                        <div class="w-16 h-16 bg-blue-100 dark:bg-blue-900 rounded-xl flex items-center justify-center mb-6">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8 text-blue-600 dark:text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                            </svg>
                        </div>
                        <h3 class="text-xl font-bold text-gray-900 dark:text-white mb-3">Easy Setup</h3>
                        <p class="text-gray-600 dark:text-gray-400">
                            Simple calibration process - just show your totem to the camera and you're ready
                        </p>
                    </div>
                </div>

                <!-- How It Works -->
                <div class="bg-gray-50 dark:bg-gray-800 rounded-3xl p-12 shadow-2xl mb-16">
                    <h2 class="text-3xl md:text-4xl font-bold text-gray-900 dark:text-white mb-8 text-center">
                        How It Works
                    </h2>
                    <div class="space-y-6">
                        <div class="flex gap-6 items-start">
                            <div class="flex-shrink-0 w-12 h-12 bg-blue-600 text-white rounded-full flex items-center justify-center font-bold text-xl">
                                1
                            </div>
                            <div>
                                <h4 class="text-xl font-bold text-gray-900 dark:text-white mb-2">Choose Your Totem</h4>
                                <p class="text-gray-600 dark:text-gray-400">Pick any object - a mug, toy, book, or anything unique that you can keep on your desk</p>
                            </div>
                        </div>
                        <div class="flex gap-6 items-start">
                            <div class="flex-shrink-0 w-12 h-12 bg-blue-600 text-white rounded-full flex items-center justify-center font-bold text-xl">
                                2
                            </div>
                            <div>
                                <h4 class="text-xl font-bold text-gray-900 dark:text-white mb-2">Calibrate</h4>
                                <p class="text-gray-600 dark:text-gray-400">Show your totem to the camera so the app can learn to recognize it</p>
                            </div>
                        </div>
                        <div class="flex gap-6 items-start">
                            <div class="flex-shrink-0 w-12 h-12 bg-blue-600 text-white rounded-full flex items-center justify-center font-bold text-xl">
                                3
                            </div>
                            <div>
                                <h4 class="text-xl font-bold text-gray-900 dark:text-white mb-2">Stay Focused</h4>
                                <p class="text-gray-600 dark:text-gray-400">Keep your totem visible on your desk to maintain access to your allowed sites. Remove it to enable website blocking</p>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- CTA Section -->
                <div class="text-center">
                    <h2 class="text-3xl font-bold text-gray-900 dark:text-white mb-4">
                        Ready to boost your productivity?
                    </h2>
                    <p class="text-xl text-gray-600 dark:text-gray-400 mb-8">
                        Available on the App Store for iPhone
                    </p>
                    <a
                        href="#"
                        class="inline-flex items-center gap-3 px-8 py-4 bg-black dark:bg-white text-white dark:text-black text-lg font-semibold rounded-xl hover:bg-gray-800 dark:hover:bg-gray-100 transition-colors shadow-xl hover:shadow-2xl"
                    >
                        <svg class="w-8 h-8" viewBox="0 0 24 24" fill="currentColor">
                            <path d="M18.71 19.5C17.88 20.74 17 21.95 15.66 21.97C14.32 22 13.89 21.18 12.37 21.18C10.84 21.18 10.37 21.95 9.09997 22C7.78997 22.05 6.79997 20.68 5.95997 19.47C4.24997 17 2.93997 12.45 4.69997 9.39C5.56997 7.87 7.12997 6.91 8.81997 6.88C10.1 6.86 11.32 7.75 12.11 7.75C12.89 7.75 14.37 6.68 15.92 6.84C16.57 6.87 18.39 7.1 19.56 8.82C19.47 8.88 17.39 10.1 17.41 12.63C17.44 15.65 20.06 16.66 20.09 16.67C20.06 16.74 19.67 18.11 18.71 19.5ZM13 3.5C13.73 2.67 14.94 2.04 15.94 2C16.07 3.17 15.6 4.35 14.9 5.19C14.21 6.04 13.07 6.7 11.95 6.61C11.8 5.46 12.36 4.26 13 3.5Z"/>
                        </svg>
                        Download on the App Store
                    </a>
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
                    <a href="/privacy-policy" class="text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors">
                        Privacy Policy
                    </a>
                </div>
            </div>
        </footer>
    </div>
</template>
