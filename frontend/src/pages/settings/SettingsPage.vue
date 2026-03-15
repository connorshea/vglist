<template>
  <section class="section">
    <div class="columns">
      <div class="column is-3">
        <aside class="menu">
          <p class="menu-label">Settings</p>
          <ul class="menu-list">
            <li>
              <router-link to="/settings/profile">Profile</router-link>
            </li>
            <li>
              <router-link to="/settings/account">Account</router-link>
            </li>
            <li>
              <router-link to="/settings/import">Import</router-link>
            </li>
            <li>
              <router-link to="/settings/export">Export</router-link>
            </li>
            <li>
              <router-link to="/settings/api-token">API Token</router-link>
            </li>
          </ul>
        </aside>
      </div>
      <div class="column">
        <router-view />
      </div>
    </div>
  </section>
</template>

<script setup lang="ts"></script>
