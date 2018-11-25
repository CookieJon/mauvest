<template lang="pug">
  <q-page class="">
    div.bg-black.fit
      j-fabric-canvas(ref='fabric' @input='onInput' :canvasOptions='canvasOptions' )
    //- <div class="row">
    //-   <q-table
    //-     title="Table Title"
    //-     :data="tableData"
    //-     :columns="columns"
    //-     :dense="false"
    //-     row-key="name"
    //-     :dark="false"
    //-     color="primary"
    //-     xclass="bg-black"
    //-   >
    //-     <q-tr slot="body" slot-scope="props" :props="props">
    //-       <q-td key="desc" :props="props">
    //-         {{ props.row.name }}
    //-         <q-popup-edit v-model="props.row.name">
    //-           <q-field count>
    //-             <q-input v-model="props.row.name" />
    //-           </q-field>
    //-         </q-popup-edit>
    //-       </q-td>
    //-       <q-td key="calories" :props="props">
    //-         {{ props.row.calories }}
    //-         <q-popup-edit v-model="props.row.calories" title="Update calories" buttons>
    //-           <q-input type="number" v-model="props.row.calories" />
    //-         </q-popup-edit>
    //-       </q-td>
    //-       <q-td key="fat" :props="props">{{ props.row.fat }}</q-td>
    //-       <q-td key="carbs" :props="props">{{ props.row.carbs }}</q-td>
    //-       <q-td key="protein" :props="props">{{ props.row.protein }}</q-td>
    //-       <q-td key="sodium" :props="props">{{ props.row.sodium }}</q-td>
    //-       <q-td key="calcium" :props="props">{{ props.row.calcium }}</q-td>
    //-       <q-td key="iron" :props="props">{{ props.row.iron }}</q-td>
    //-     </q-tr>
    //-   </q-table>
    //- </div>
  </q-page>
</template>

<style>
</style>

<script>
/* eslint-disable */

import tableData from 'assets/table-data'
import { fabric } from 'fabric'
import jFabricCanvas from 'components/j-fabric-canvas'
var canvas
export default {
  name: 'PageIndex',
  components: { jFabricCanvas },
  data: () => ({
    // Fabric canvas things...
    canvasOptions: {
      isDrawingMode: true,
      preserveObjectStacking: false,
      imageSmoothingEnabled: false
    },
    objects: [],
    selectedObject: null,

    tableData,
    columns: [
      { name: 'desc', required: true, label: 'Dessert (100g serving)', align: 'left', field: 'name', sortable: true },
      { name: 'calories', label: 'Calories', field: 'calories', sortable: true },
      { name: 'fat', label: 'Fat (g)', field: 'fat', sortable: true },
      { name: 'carbs', label: 'Carbs (g)', field: 'carbs' },
      { name: 'protein', label: 'Protein (g)', field: 'protein' },
      { name: 'sodium', label: 'Sodium (mg)', field: 'sodium' },
      { name: 'calcium', label: 'Calcium (%)', field: 'calcium', sortable: true, sort: (a, b) => parseInt(a, 10) - parseInt(b, 10) },
      { name: 'iron', label: 'Iron (%)', field: 'iron', sortable: true, sort: (a, b) => parseInt(a, 10) - parseInt(b, 10) }
    ]
  }),
  methods: {
   // Fabric emitted 'input' event
    onInput(e) {
      console.log('input', e)
      this.objects = extend({}, e)
    },
  },
  mounted () {
      // Init fabric canvas
      console.log(fabric)
      canvas = new fabric.Canvas('c', {imageSmoothingEnabled: false})
  }
}
</script>
