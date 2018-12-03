// import something here

// TODO
// import moe.actions

import dropzone from '../directives/dropzone.js'

// leave the export, even if you don't use it
export default ({ app, router, Vue }) => {

  Vue.directive('dropzone', dropzone)

}
