//
//  AQTGraphicDrawingMethods.m
//  AquaTerm
//
//  Created by Per Persson on Mon Oct 20 2003.
//  Copyright (c) 2003-2012 The AquaTerm Team. All rights reserved.
//

#import "AQTGraphicDrawingMethods.h"

#import "AQTLabel.h"
#import "AQTPath.h"
#import "AQTImage.h"
#import "AQTFunctions.h"
#import "AQTStringDrawingAdditions.h"

/* _aqtMinimumLinewidth is used by view to pass user prefs to line drawing routine,
this is ugly, but I can't see a simple way to do it without affecting performance. */
static float _aqtMinimumLinewidth; 

@implementation AQTGraphic (AQTGraphicDrawingMethods)
- (void)setAQTColor
{
   static AQTColor currentColor;
   if (!AQTEqualColors(currentColor, _color)) {
      [[NSColor colorWithCalibratedRed:_color.red
                                 green:_color.green
                                  blue:_color.blue
                                 alpha:_color.alpha] set];
      currentColor = _color;
   }
}

-(void)renderInRect:(NSRect)boundsRect
{
   NSLog(@"Error: *** AQTGraphicDrawing ***");
}

-(NSRect)updateBounds
{
   return _bounds; // Default is to do nothing.
}

-(void)_setCache:(id)object
{
   [object retain];
   [_cache release];
   _cache = object;
}

-(id)_cache
{
   return _cache;
}

@end

/**"
*** Tell every object in the collection to draw itself.
"**/
@implementation AQTModel (AQTModelDrawing)
-(NSRect)updateBounds
{
   NSRect tmpRect = NSZeroRect;
   AQTGraphic *graphic;
   NSEnumerator *enumerator = [modelObjects objectEnumerator];
   
   _aqtMinimumLinewidth = [[NSUserDefaults standardUserDefaults] floatForKey:@"MinimumLinewidth"];
   
   while ((graphic = [enumerator nextObject]))
   {
      /*       NSRect graphRect = [graphic updateBounds];
      
      if (NSIsEmptyRect(graphRect))
   {
         NSLog(@"**** rect = %@ : %@", NSStringFromRect(graphRect), [graphic description]);
   }
      
      tmpRect = AQTUnionRect(tmpRect, graphRect);
      */
      tmpRect = AQTUnionRect(tmpRect, [graphic updateBounds]);
   }
   [self setBounds:tmpRect];
   return tmpRect;
}

-(void)renderInRect:(NSRect)aRect
{
   AQTGraphic *graphic;
   NSEnumerator *enumerator = [modelObjects objectEnumerator];
   
   // Model object is responsible for background...
   [self setAQTColor];
   // FIXME: needed to synchronize colors
   [[NSColor colorWithCalibratedRed:_color.red green:_color.green blue:_color.blue alpha:1.0] set];
   NSRectFill(aRect);
   
   while ((graphic = [enumerator nextObject])) {
      [graphic renderInRect:aRect];
   }
}
@end

@implementation AQTLabel (AQTLabelDrawing)
-(void)_aqtLabelUpdateCache
{
   NSFont *normalFont; 
   NSAffineTransform *aTransform = [NSAffineTransform transform];
   NSAffineTransform *shearTransform = [NSAffineTransform transform];
   NSAffineTransformStruct ts;
   NSBezierPath *tmpPath = [NSBezierPath bezierPath];
   NSSize tmpSize;
   NSPoint adjust = NSZeroPoint;
   // Make sure we get a valid font....
   if ((normalFont = [NSFont fontWithName:fontName size:fontSize]) == nil)
      normalFont = [NSFont systemFontOfSize:fontSize]; // Fall back to a system font 
                                                       // Convert (attributed) string into a path
   tmpPath = [string aqtBezierPathInFont:normalFont]; // Implemented in AQTStringDrawingAdditions
   tmpSize = [tmpPath bounds].size;
   // Place the path according to position, angle and align  
   adjust.x = -(float)(justification & 0x03)*0.5*tmpSize.width; // hAlign:
   switch (justification & 0x1C) { // vAlign:
      case 0x00:// AQTAlignMiddle: // align middle wrt *font size*
         adjust.y = -([normalFont descender] + [normalFont capHeight])*0.5; 
         break;
      case 0x08:// AQTAlignBottom: // align bottom wrt *bounding box*
         adjust.y = -[tmpPath bounds].origin.y;
         break;
      case 0x10:// AQTAlignTop: // align top wrt *bounding box*
         adjust.y = -([tmpPath bounds].origin.y + tmpSize.height) ;
         break;
      case 0x04:// AQTAlignBaseline: // align baseline (do nothing)
      default:
         // default to align baseline (do nothing) in case of error
         break;
   }
   // Avoid multiples of 90 degrees (pi/2) since tan(k*pi/2)=inf, set beta to 0.0 instead. 
   float beta = (fabs(shearAngle - 90.0*roundf(shearAngle/90.0))<0.1)?0.0:-shearAngle;
   // shearTransform is an identity transform so we can just stuff the shearing into m21...
   ts = [shearTransform transformStruct];
   ts.m21 = -tan(beta*atan(1.0)/45.0); // =-tan(beta*pi/180.0)
   [shearTransform setTransformStruct:ts];
   [tmpPath transformUsingAffineTransform:shearTransform];
   // Now, place the sheared label correctly
   [aTransform translateXBy:position.x yBy:position.y];
   [aTransform rotateByDegrees:angle];
   [aTransform translateXBy:adjust.x yBy:adjust.y]; 
   [tmpPath transformUsingAffineTransform:aTransform];
   
   [self _setCache:tmpPath];
}

-(NSRect)updateBounds
{
   NSRect tempBounds;
   if (![self _cache]) {
      [self _aqtLabelUpdateCache];
   }
   tempBounds = [_cache bounds];
   [self setBounds:tempBounds];
   return tempBounds;
}

-(void)renderInRect:(NSRect)boundsRect
{
   NSGraphicsContext *context;
   NSRect clippedBounds = _isClipped?NSIntersectionRect(_bounds, _clipRect):_bounds;
   if (AQTIntersectsRect(boundsRect, clippedBounds)) {
      [self setAQTColor];
      if (_isClipped) {
         context = [NSGraphicsContext currentContext];
         [context saveGraphicsState];
         NSRectClip(clippedBounds);
         [_cache  fill];
         [context restoreGraphicsState];
      } else {
      [_cache  fill];
      }
   }
#ifdef DEBUG_BOUNDS
   if (_shouldShowBounds) {
      NSGraphicsContext *debugContext = [NSGraphicsContext currentContext];
      [debugContext saveGraphicsState];
      [[NSColor yellowColor] set];
      NSFrameRect([self bounds]);
      if (_isClipped) {
         [[NSColor orangeColor] set];
         NSFrameRect(_clipRect);
      }
      [debugContext restoreGraphicsState];
   }
#endif
}
@end

@implementation AQTPath (AQTPathDrawing)
-(void)_aqtPathUpdateCache
{
   int32_t i;
   float lw = [self isFilled]?1.0:linewidth; // FIXME: this is a hack to avoid tiny gaps between filled patches
   NSBezierPath *scratch = [NSBezierPath bezierPath];
   [scratch appendBezierPathWithPoints:path count:pointCount];
   [scratch setLineJoinStyle:NSRoundLineJoinStyle]; //CM FIXME - This looks like a bug. This explains why join styles don't work in the TestView... //CM
   [scratch setLineCapStyle:lineCapStyle];
   [scratch setLineWidth:(lw<_aqtMinimumLinewidth)?_aqtMinimumLinewidth:lw];
   if([self hasPattern]) {
       CGFloat temppat[patternCount];
       for( i = 0; i < patternCount; i++) temppat[i] = pattern[i];
      [scratch setLineDash:temppat count:patternCount phase:patternPhase];
   }
   if([self isFilled]) {
      [scratch closePath];
   }
   if(EQ(path[0].x, path[pointCount-1].x) && EQ(path[0].y, path[pointCount-1].y)) {
      // This looks like a closed path..., make it so.
      [scratch closePath];      
   }
   [self _setCache:scratch];
}

-(NSRect)updateBounds
{
   NSRect tmpBounds;
   if (![self _cache]) {
      [self _aqtPathUpdateCache];
   }   
   tmpBounds = NSInsetRect([[self _cache] bounds], -linewidth/2, -linewidth/2);
   [self  setBounds:tmpBounds];
   return tmpBounds;
}

-(void)renderInRect:(NSRect)boundsRect
{
   NSGraphicsContext *context;
   NSRect clippedBounds = _isClipped?NSIntersectionRect(_bounds, _clipRect):_bounds;
   if (AQTIntersectsRect(boundsRect, clippedBounds)) {
      [self setAQTColor];
      if (_isClipped) {
         context = [NSGraphicsContext currentContext];
         [context saveGraphicsState];
         NSRectClip(clippedBounds);
      }
      [_cache stroke];
      if ([self isFilled]) {
         [_cache fill];
      }
      if (_isClipped)
         [context restoreGraphicsState];
   }
#ifdef DEBUG_BOUNDS
   if (_shouldShowBounds) {
      NSGraphicsContext *debugContext = [NSGraphicsContext currentContext];
      [debugContext saveGraphicsState];
      [[NSColor yellowColor] set];
      NSFrameRect([self bounds]);
      if (_isClipped) {
         [[NSColor orangeColor] set];
         NSFrameRect(_clipRect);
      }
      [debugContext restoreGraphicsState];
   }
#endif
   
}
@end

@implementation AQTImage (AQTImageDrawing)

NSAffineTransformStruct AQTConvertTransformStructToNS(AQTAffineTransformStruct t)
{
    NSAffineTransformStruct tmp = {
        .m11 = (CGFloat)t.m11,
        .m12 = (CGFloat)t.m12,
        .m21 = (CGFloat)t.m21,
        .m22 = (CGFloat)t.m22,
        .tX = (CGFloat)t.tX,
        .tY = (CGFloat)t.tY
    };
    return tmp;
}

-(NSRect)updateBounds
{
   NSAffineTransform *transf = [NSAffineTransform transform];
   NSRect tmpBounds;
   if (fitBounds)
   {
      tmpBounds = [self bounds];
   } else {
      [transf setTransformStruct:AQTConvertTransformStructToNS(transform)];
      // FIXME: This is lazy beyond any reasonable measure...
      tmpBounds = [[transf transformBezierPath:[NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, bitmapSize.width, bitmapSize.height)]] bounds];
      [self  setBounds:tmpBounds];
   }
   return tmpBounds;
}

-(void)renderInRect:(NSRect)boundsRect
{
   NSGraphicsContext *context;
   NSRect clippedBounds = _isClipped?NSIntersectionRect(_bounds, _clipRect):_bounds;
   if (AQTIntersectsRect(boundsRect, clippedBounds)) {
      if (![self _cache]) {
         // Install an NSImage in _cache
         unsigned char *theBytes = (unsigned char*) [bitmap bytes];
         NSImage *tmpImage = [[NSImage alloc] initWithSize:bitmapSize];
         NSBitmapImageRep *tmpBitmap =
            [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&(theBytes)
                                                    pixelsWide:bitmapSize.width
                                                    pixelsHigh:bitmapSize.height
                                                 bitsPerSample:8
                                               samplesPerPixel:3
                                                      hasAlpha:NO
                                                      isPlanar:NO
                                                colorSpaceName:NSDeviceRGBColorSpace
                                                   bytesPerRow:3*bitmapSize.width
                                                  bitsPerPixel:24];
         [tmpImage addRepresentation:tmpBitmap];
         [self _setCache:tmpImage];
         [tmpImage release];
         [tmpBitmap release];
      }
      if (_isClipped) {
         context = [NSGraphicsContext currentContext];
         [context saveGraphicsState];
         NSRectClip(clippedBounds);
      }
      if (fitBounds == YES) {
         [_cache drawInRect:_bounds
                   fromRect:NSMakeRect(0,0,[_cache size].width,[_cache size].height)
                  operation:NSCompositeSourceOver
                   fraction:1.0];
      } else {
         NSAffineTransform *transf = [NSAffineTransform transform];
         
         // If the image is clipped, the state is already stored
         if (!_isClipped) {
            context = [NSGraphicsContext currentContext];
            [context saveGraphicsState];
         }
         [transf setTransformStruct:AQTConvertTransformStructToNS(transform)];
         [transf concat];
         [_cache drawAtPoint:NSMakePoint(0,0)
                    fromRect:NSMakeRect(0,0,[_cache size].width,[_cache size].height)
                   operation:NSCompositeSourceOver
                    fraction:1.0];
         if (!_isClipped)
            [context restoreGraphicsState];
      }
      if (_isClipped)
         [context restoreGraphicsState];
   }
#ifdef DEBUG_BOUNDS
   if (_shouldShowBounds) {
      NSGraphicsContext *debugContext = [NSGraphicsContext currentContext];
      [debugContext saveGraphicsState];
      [[NSColor yellowColor] set];
      NSFrameRect([self bounds]);
      if (_isClipped) {
         [[NSColor orangeColor] set];
         NSFrameRect(_clipRect);
      }
      [debugContext restoreGraphicsState];
   }
#endif
   
}
@end

