<template>
  <div class="zenon-app">
    <ChatInterface />
  </div>
</template>

<script setup>
// Page meta
useHead({
  title: 'NoM Query Interface'
})
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Montserrat:wght@300;400;500;600;700&display=swap');
@import url('https://fonts.googleapis.com/icon?family=Material+Icons');

.zenon-app {
  font-family: 'Montserrat', sans-serif;
  background: linear-gradient(135deg, #0a0a0a 0%, #151515 50%, #0a0a0a 100%);
  color: #ffffff;
  min-height: 100vh;
  position: relative;
}

.zenon-app::before {
  content: '';
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: 
    radial-gradient(circle at 20% 20%, rgba(111, 243, 77, 0.03) 0%, transparent 50%),
    radial-gradient(circle at 80% 80%, rgba(111, 243, 77, 0.02) 0%, transparent 50%),
    radial-gradient(circle at 40% 60%, rgba(111, 243, 77, 0.01) 0%, transparent 50%);
  pointer-events: none;
  z-index: 0;
}

/* Global override */
:global(html), :global(body) {
  background-color: #151515 !important;
  color: #ffffff !important;
  font-family: 'Montserrat', sans-serif !important;
}

/* Ensure chat container is above background */
:global(.chat-container) {
  position: relative;
  z-index: 1;
}
</style>