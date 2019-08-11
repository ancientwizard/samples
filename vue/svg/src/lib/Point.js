// Point
// Author: V Burns (ancient.wizard@verizon.net)
//  Not necessarily a new work as it is based on well established Mathmatics
//  its simply my take on it

export default
function Point ( arga, argb )
{
    this.x = ( arga && arga instanceof Array ? arga[0] : arga ) || 0
    this.y = ( arga && arga instanceof Array ? arga[1] : argb ) || 0

    if ( isNaN( this.x )) throw 'x [' + this.x + '] is Not a Number'
    if ( isNaN( this.y )) throw 'y [' + this.y + '] is Not a Number'

    // Methods
    // clone this object
    this.clone = function () { return new Point( this.x, this.y ) }

    // add another point to this one returning
    //  a new object
    this.add = function ( arga, argb )
    {
        this.x += (( arga && arga instanceof Point ? arga.x
                   : arga && arga instanceof Array ? arga[0] : arga ) || 0 )
        this.y += (( arga && arga instanceof Point ? arga.y
                   : arga && arga instanceof Array ? arga[1] : argb ) || 0 )

        return this
    }

    // angle
    this.angle = function ( angle )
    {
      if ( isNaN( angle ))
      {
        angle = Math.atan2( this.y, this.x ) * 180 / Math.PI
      }
      else
      {
        let radius = this.length()
        this.x = radius * Math.cos( angle * Math.PI / 180 )
        this.y = radius * Math.sin( angle * Math.PI / 180 )
      }

      return angle
    };

    // Divide
    this.divide = function ( arga, argb )
    {
      arga && arga instanceof Array && ( argb = arga[1], arga = arga[0] )
      arga && arga instanceof Point && ( argb = arga.y,  arga = arga.x  )

      if ( isNaN( arga )) throw 'x [' + arga + '] is Not a Number'
      if ( isNaN( argb )) throw 'y [' + argb + '] is Not a Number'

      return new Point( this.x / arga, this.y /= argb )
    }

    // Equals
    this.equals = function ( arga, argb )
    {
      arga && arga instanceof Array && ( argb = arga[1], arga = arga[0] )
      arga && arga instanceof Point && ( argb = arga.y,  arga = arga.x  )

      if ( isNaN( arga )) throw 'x [' + arga + '] is Not a Number'
      if ( isNaN( argb )) throw 'y [' + argb + '] is Not a Number'

      return this.x == arga && this.y == argb
    }

    // Test for ZERO's
    this.isZero = function () { return this.x == 0 && this.y == 0 }

    // length() gets or gets the Length
    this.length = function( length )
    {
      if ( isNaN( length ))
      {
        // Okay compute our current length
        length = Math.sqrt( this.x * this.x + this.y * this.y )
      }
      else
      {
        // update X, Y to match requested Length
        let angle = this.angle()
        this.x = length * Math.cos(angle)
        this.y = length * Math.sin(angle)
      }

      return length;
    }

    // Modulo
    this.modulo = function ( arga, argb )
    {
      arga && arga instanceof Array && ( argb = arga[1], arga = arga[0] )
      arga && arga instanceof Point && ( argb = arga.y,  arga = arga.x  )

      if ( isNaN( arga )) throw 'x [' + arga + '] is Not a Number'
      if ( isNaN( argb )) throw 'y [' + argb + '] is Not a Number'

      return new Point( this.x & arga, this.y % argb )
    }

    // multiply
    this.multiply = function ( arga, argb )
    {
      arga && arga instanceof Array && ( argb = arga[1], arga = arga[0] )
      arga && arga instanceof Point && ( argb = arga.y,  arga = arga.x  )

      if ( isNaN( arga )) throw 'x [' + arga + '] is Not a Number'
      if ( isNaN( argb )) throw 'y [' + argb + '] is Not a Number'

      return new Point( this.x * arga, this.y * argb );
    }

    // negate
    this.negate = function () { return new Point( -this.x, -this.y ) }

    // normalize( length (optional))
    this.normalize = function ( length )
    {
      let point = this.clone();
      point.length( length === undefined ? 1 : length )
      return point
    }

    // rotate( angle, [ center ](optinal) )
    this.rotate = function ( angle, center )
    {
      if ( angle === 0 ) return this.clone()

      angle = angle * Math.PI / 180

      var point = center ? this.clone().subtract( center ) : this,
            sin = Math.sin( angle ),
            cos = Math.cos( angle )

      point = new Point(
        point.x * cos - point.y * sin,
        point.x * sin + point.y * cos )

      return center ? point.add( center ) : point;
    }

    // scale()
    this.scale = function ( scalefactor )
    {
      if ( isNaN( scalefactor )) throw 'scalefactor [' + scalefactor + '] is Not a Number'

      return new Point( this.x * scalefactor, this.y * scalefactor )
    }

    // Set
    this.set = function ( arga, argb )
    {
      arga && arga instanceof Array && ( argb = arga[1], arga = arga[0] )
      arga && arga instanceof Point && ( argb = arga.y,  arga = arga.x  )

      if ( isNaN( arga )) throw 'x [' + arga + '] is Not a Number'
      if ( isNaN( argb )) throw 'y [' + argb + '] is Not a Number'

      this.x = arga;  this.y = argb

      return this
    }

    this.setX = function ( _x )
    {
      if ( isNaN( _x )) throw 'x [' + _x + '] is Not a Number'
      this.x = _x
      return this
    }

    this.setY = function ( _y )
    {
      if ( isNaN( _y )) throw 'y [' + _y + '] is Not a Number'
      this.y = _y
      return this
    }

    // Subtract
    this.subtract = function ( arga, argb )
    {
        this.x -= (( arga && arga instanceof Point ? arga.x
                   : arga && arga instanceof Array ? arga[0] : arga ) || 0 )
        this.y -= (( arga && arga instanceof Point ? arga.y
                   : arga && arga instanceof Array ? arga[1] : argb ) || 0 )

        return this
    }

    this.toArray  = function () { return [ this.x, this.y ] }
    this.toString = function () { return "Point( " + this.x + ', ' + this.y + ' )' }

    return this
}


//console.log( new Point())
//console.log( new Point(-8, 2 ).clone())
//console.log( new Point(-8, 2 ).add(new Point(9,4)));
//console.log( new Point(-8, 2 ).add([9,4]).add(-5,-2));
//console.log( new Point(5,7).equals(new Point(5,7)));
//console.log( new Point(5,4).scale(5.5))
//console.log( new Point(-8, 2 ).subtract([9,4]).subtract(-5,-2));

//let p = new Point( 5, 5 )
//console.log(p.angle())
//console.log(p.length())

// Point( x, y || [ x, y ] )
