// Firebase Messaging Service Worker for Flutter Web
// This enables background notifications on the web.
// It must be located at the root of the web folder with this exact filename.

importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js');

// These values come from lib/firebase_options.dart (web section)
firebase.initializeApp({
    apiKey: 'AIzaSyCQVVqssk1aMPh5cgJi2a3XAqFJ2_cOXPc',
    appId: '1:955408721623:web:e78c39e6801db32545b292',
    messagingSenderId: '955408721623',
    projectId: 'apisavana-bf-226',
    authDomain: 'apisavana-bf-226.firebaseapp.com',
    storageBucket: 'apisavana-bf-226.firebasestorage.app',
    measurementId: 'G-NH4D0Q9NTS',
});

const messaging = firebase.messaging();

// Show a notification when a message arrives in the background
messaging.onBackgroundMessage((payload) => {
    const title = (payload.notification && payload.notification.title) || payload.data?.titre || 'Notification';
    const body = (payload.notification && payload.notification.body) || payload.data?.message || '';
    const options = {
        body,
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
        data: payload.data || {},
    };
    self.registration.showNotification(title, options);
});
