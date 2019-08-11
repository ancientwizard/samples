<template>
  <div class="void">
    <svg height="300" ref="ws" id="ws">
<!--
      <path d="M 10,30
             A 20,20 0,0,1 50,30
             A 20,20 0,0,1 90,30
             Q 90,60 50,90
             Q 10,60 10,30 z" style="fill:red;stroke:white;stroke-width:1"/>

      <polyline points="110,80 140,55 155,65 175,35 185,40 220,10"
          full="none" stroke="white" />

          <filter x="-56.9%" y="-145.1%" width="217.1%" height="421.1%" filterUnits="objectBoundingBox" id="sparc-glow-1">
-->

      <filter x="0" y="0" width="800" height="800" filterUnits="objectBoundingBox" id="sparc-glow-1">
        <feOffset dx="0" dy="0" in="SourceAlpha" result="shadowOffsetOuter1"></feOffset>
        <feGaussianBlur stdDeviation="5" in="shadowOffsetOuter1" result="shadowBlurOuter1"></feGaussianBlur>
        <feColorMatrix values="0 0 0 0 1   0 0 0 0 1   0 0 0 0 1  0 0 0 1 0" type="matrix" in="shadowBlurOuter1" result="shadowMatrixOuter1"></feColorMatrix>
        <feOffset dx="0" dy="1" in="SourceAlpha" result="shadowOffsetOuter2"></feOffset>
        <feGaussianBlur stdDeviation="7" in="shadowOffsetOuter2" result="shadowBlurOuter2"></feGaussianBlur>
        <feColorMatrix values="0 0 0 0 1   0 0 0 0 1   0 0 0 0 1  0 0 0 0.9 0" type="matrix" in="shadowBlurOuter2" result="shadowMatrixOuter2"></feColorMatrix>
        <feOffset dx="0" dy="2" in="SourceAlpha" result="shadowOffsetOuter3"></feOffset>
        <feGaussianBlur stdDeviation="10" in="shadowOffsetOuter3" result="shadowBlurOuter3"></feGaussianBlur>
        <feColorMatrix values="0 0 0 0 1   0 0 0 0 1   0 0 0 0 1  0 0 0 0.8 0" type="matrix" in="shadowBlurOuter3" result="shadowMatrixOuter3"></feColorMatrix>
        <feOffset dx="2" dy="2" in="SourceAlpha" result="shadowOffsetOuter4"></feOffset>
        <feGaussianBlur stdDeviation="1" in="shadowOffsetOuter4" result="shadowBlurOuter4"></feGaussianBlur>
        <feColorMatrix values="0 0 0 0 0   0 0 0 0 0   0 0 0 0 0  0 0 0 0.69678442 0" type="matrix" in="shadowBlurOuter4" result="shadowMatrixOuter4"></feColorMatrix>
        <feOffset dx="0" dy="2" in="SourceAlpha" result="shadowOffsetOuter5"></feOffset>
        <feGaussianBlur stdDeviation="8" in="shadowOffsetOuter5" result="shadowBlurOuter5"></feGaussianBlur>
        <feColorMatrix values="0 0 0 0 0.314369351   0 0 0 0 0.8883757   0 0 0 0 0.759899616  0 0 0 0.649371603 0" type="matrix" in="shadowBlurOuter5" result="shadowMatrixOuter5"></feColorMatrix>
        <feMerge>
          <feMergeNode in="shadowMatrixOuter1"></feMergeNode>
          <feMergeNode in="shadowMatrixOuter2"></feMergeNode>
          <feMergeNode in="shadowMatrixOuter3"></feMergeNode>
          <feMergeNode in="shadowMatrixOuter4"></feMergeNode>
          <feMergeNode in="shadowMatrixOuter5"></feMergeNode>
        </feMerge>
      </filter>

<!--
      <filter
         inkscape:label="Inset"
         inkscape:menu="Shadows and Glows"
         inkscape:menu-tooltip="Shadowy outer bevel"
         style="color-interpolation-filters:sRGB;"
         id="spark-glow-2"
         x="-0.10000000000000001">
        <feMorphology   result="result1" in="SourceAlpha" operator="dilate" radius="3.6" id="feMorphology929" />
        <feGaussianBlur stdDeviation="3.6" in="result1" result="result0" id="feGaussianBlur931" />
        <feDiffuseLighting surfaceScale="-1.8180000000000001" id="feDiffuseLighting935"
           lighting-color="rgb(226,226,226)" diffuseConstant="1.1299999999999999" kernelUnitLength="0.01">
          <feDistantLight id="feDistantLight949" azimuth="160" elevation="33" />
        </feDiffuseLighting>
        <feComposite in2="result0" operator="in" result="result91" id="feComposite937" />
        <feComposite in="SourceGraphic" in2="result91" id="feComposite939" result="result92" />
        <feBlend mode="normal" in2="result92" id="feBlend951" />
      </filter>
-->
    </svg>
  </div>
</template>

<script>
// @ is an alias to /src
// import HelloWorld from '@/components/HelloWorld.vue'

// import { Point } from 'paper';
import Point from '@/lib/Point.js';

export default {
  name: 'shocker',
  components: {
  },

  // Methods
  methods: {
    CreateBolt: function () // source, dest, thickness )
    {
      let results = []
      let source  = new Point( 10, 270 )
      let dest    = new Point( 180, 45 )
      let tangent = dest.clone().subtract( source )

      // console.log( tangent )

      let normal = tangent.clone().setX( - tangent.x ).normalize()
      let length = tangent.length()
      let positions = [0]

      for ( let i = 0 ; i < length / 4 ; i++ )
          positions.push(Math.random())

      positions.sort()
      results.push( source.toArray())

      let Sway = 30
      const Jaggedness = 1 / Sway

      let prevPoint = source
      let prevDisplacement = 0

      for ( let i = 1 ; i < positions.length ; i++ )
      {
        let pos = positions[i];

        // used to prevent sharp angles by ensuring very close positions also have small perpendicular variation.
        let scale = ( length * Jaggedness ) * ( pos - positions[ i - 1 ])

        // defines an envelope. Points near the middle of the bolt can be further from the central line.
        let envelope = pos > 0.95 ? 20 * ( 1 - pos ) : 1

        let displacement = Math.random() * ( Sway * 2 ) - Sway
        displacement -= ( displacement - prevDisplacement ) * ( 1 - scale )
        displacement *= envelope

        // C# converted to javascript, ouch!
        // point = source + pos * tangent + displacement * normal;
        let point = source.clone().add(tangent.clone().multiply( pos, pos ).add( normal.clone().multiply( displacement, displacement )))

        results.push( point.toArray() )
//      results.push(new Line(prevPoint, point, thickness));
        prevPoint = point;
        prevDisplacement = displacement;
      }

//    results.Add(new Line(prevPoint, dest, thickness));
      results.push( dest.toArray() )

      return results;
    }

  },

  // Mounted
  mounted: function ()
  {
    let self = this
    let cnt  = 250
    let line

//    this.$nextTick( function () {
    let interval =
    window.setInterval( function ()
    {
      try {
        // First lets create our drawing surface out of existing SVG element
        // If you want to create new surface just provide dimensions
        let s = new Snap('#ws');

        // Lightning
        line && line.remove()
        line = s.polyline(self.CreateBolt()).attr(
          { stroke:"#fafaff" //stroke:"#ffffff"
  //        , filter:url("#spark-glow-1")
  //        , 'fill':none
  //        , 'fill-opacity':0.5
          , 'stroke-width':0.9
  //      , 'stroke-linecap':round
  //        , 'stroke-linejoin':miter
          , 'stroke-miterlimit':4
  //        , 'stroke-dasharray':none
          , 'stroke-opacity':0.8
          });

        cnt-- || window.clearInterval( interval )
      }
      catch ( err ) { console.log( err ) }
    }, 40 );
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>

p {
  x-background-color: black;
}

.void {
  background-color: black;
}

</style>

// END
