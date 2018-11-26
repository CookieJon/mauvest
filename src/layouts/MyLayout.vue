<template lang='pug'>
  q-layout(view="hHh LpR fFf" :xstyle="bgStyle")
    q-layout-header.bg-dark(style='-webkit-app-region: drag')
      q-toolbar(
        xcolor="dark"
        xtext-color='white'
        :inverted="false"
        :xinverted="$q.theme === 'mat'"
        :xglossy="$q.theme === 'ios'"
      )    
      q-toolbar(
        xcolor="dark"
        xtext-color='white'
        :inverted="false"
        :xinverted="$q.theme === 'mat'"
        :xglossy="$q.theme === 'ios'"
      )
        q-btn(flat size='lg' @click="leftDrawerOpen = !leftDrawerOpen" aria-label="Menu" style='-webkit-app-region: no-drag')
          q-icon(name="menu")

        q-toolbar-title
          |Electron
          //div(slot="subtitle") Running on Quasar v{{ $q.version }}

        q-btn(flat size='lg' @click="rightDrawerOpen = !rightDrawerOpen" aria-label="Menu" style='-webkit-app-region: no-drag')
          q-icon(name="menu")

    q-layout-drawer(
      v-model="leftDrawerOpen"
      :content-class="$q.theme === 'mat' ? 'bg-grey-2' : null"
    )
      <q-list>
        <q-collapsible icon="explore" label="First">
          div
            q-color-picker(v-model="modelHex" class="xabsolute-center")

          <div>

            q-field(
              icon="cloud"
              label="Gmail"
              helper="Helper"
              :error="true"
              error-label="We need a valid email"
              :count="10"
            )
              <q-input suffix="@gmail.com" v-model="test1" />

            q-field(count)
              q-select(
                v-model="test1"
                :options=`[
                  {
                    label: 'Google',
                    icon: 'email',
                    value: 'goog'
                  },
                  {
                    label: 'Facebook',
                    description: 'Enables communication',
                    value: 'fb'
                  },
                  {
                    label: 'Twitter',
                    secondIcon: 'alarm',
                    value: 'twtr'
                  }
                ]`
              )

          </div>
        </q-collapsible>
        <q-collapsible icon="perm_identity" label="Second">
          <div>
            Content
          </div>
        </q-collapsible>
        <q-collapsible icon="shopping_cart" label="Third">
          <div>
            Content
          </div>
        </q-collapsible>
      </q-list>


    q-layout-drawer(
      side="right"
      v-model="rightDrawerOpen"
      :content-class="$q.theme === 'mat' ? 'bg-grey-2' : null"
    )
      q-list( no-border link inset-delimiter)
        <q-list-header>
         
        </q-list-header>
        //- <q-item @click.native="openURL('http://quasar-framework.org')">
        //-   <q-item-side icon="school" />
        //-   <q-item-main label="Docs" sublabel="quasar-framework.org" />
        //- </q-item>
        //- <q-item @click.native="openURL('https://github.com/quasarframework/')">
        //-   <q-item-side icon="code" />
        //-   <q-item-main label="GitHub" sublabel="github.com/quasarframework" />
        //- </q-item>
        //- <q-item @click.native="openURL('https://discord.gg/5TDhbDg')">
        //-   <q-item-side icon="chat" />
        //-   <q-item-main label="Discord Chat Channel" sublabel="https://discord.gg/5TDhbDg" />
        //- </q-item>
        //- <q-item @click.native="openURL('http://forum.quasar-framework.org')">
        //-   <q-item-side icon="record_voice_over" />
        //-   <q-item-main label="Forum" sublabel="forum.quasar-framework.org" />
        //- </q-item>
        //- <q-item @click.native="openURL('https://twitter.com/quasarframework')">
        //-   <q-item-side icon="rss feed" />
        //-   <q-item-main label="Twitter" sublabel="@quasarframework" />
        //- </q-item>
      </q-list>


    <q-page-container>
      <router-view />
    </q-page-container>

    <!-- Footer -->
    //- q-layout-footer(v-model="footerOpen")
    //-   q-toolbar(color="primary" :inverted="$q.theme === 'mat'" :glossy="$q.theme === 'ios'")
    //-     <img alt="Quasar logo" src="~assets/quasar-logo-full.svg" height='80' />
    //-     q-btn(flat dense @click="leftDrawerOpen = !leftDrawerOpen" aria-label="Menu")
    //-       <q-icon name="menu" />
    //-     </q-btn>

    //-     <q-toolbar-title>
    //-       Quasar App
    //-       <div slot="subtitle">Running on Quasar v{{ $q.version }}</div>
    //-     </q-toolbar-title>
    //-   </q-toolbar>

</template>

<script>
import { openURL, colors } from 'quasar'

export default {
  name: 'MyLayout',
  data () {
    return {
      leftDrawerOpen: this.$q.platform.is.desktop,
      rightDrawerOpen: this.$q.platform.is.desktop,
      footerOpen: this.$q.platform.is.desktop,
      test1: 'test1',
      test2: 'test1',
      
      modelHex: '#C7044B'
    }
  },
  watch: {
    modelHex: {
      handler (val, oldVal) {
        colors.setBrand('primary', val)
      },
      immediate: true
    }
  },  
  computed: {
    'bgStyle' () {
      return {
        'background-color': 'white'
        // 'background-image': 'url(' + this.selectedBg + ')'
      }
    }
  },
  methods: {
    openURL
  }
}
</script>

<style>
</style>
