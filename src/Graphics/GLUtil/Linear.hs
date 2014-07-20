{-# LANGUAGE FlexibleInstances, FlexibleContexts, ScopedTypeVariables #-}
{-# OPTIONS_GHC -cpp -pgmPcpphs -optP--cpp -optP--hashes #-}
-- |Support for writing "Linear" types to uniform locations in
-- shader programs.
module Graphics.GLUtil.Linear (AsUniform(..)) where
import Foreign.Marshal.Array (withArray)
import Foreign.Marshal.Utils (with)
import Foreign.Ptr (Ptr, castPtr)
import Graphics.Rendering.OpenGL (UniformLocation)
import Graphics.Rendering.OpenGL.Raw.Core31
import Linear
import Unsafe.Coerce (unsafeCoerce)

-- | A type class for things we can write to uniform locations in
-- shader programs.
class AsUniform t where
  asUniform :: t -> UniformLocation -> IO ()

getUL :: UniformLocation -> GLint
getUL = unsafeCoerce

castVecComponent :: Ptr (t a) -> Ptr a
castVecComponent = castPtr

castMatComponent :: Ptr (t (f a)) -> Ptr a
castMatComponent = castPtr

instance AsUniform GLint where
  x `asUniform` loc = with x $ glUniform1iv (getUL loc) 1

instance AsUniform GLuint where
  x `asUniform` loc = with x $ glUniform1uiv (getUL loc) 1

instance AsUniform GLfloat where
  x `asUniform` loc = with x $ glUniform1fv (getUL loc) 1

#define UNIFORMVEC_T(d,ht,glt) instance AsUniform (V ## d ht) where {v `asUniform` loc = with v $ glUniform##d##glt##v (getUL loc) 1 . castVecComponent}

#define UNIFORMVEC(d) UNIFORMVEC_T(d,GLint,i); UNIFORMVEC_T(d,GLuint,ui); UNIFORMVEC_T(d,GLfloat,f)

UNIFORMVEC(1)
UNIFORMVEC(2)
UNIFORMVEC(3)
UNIFORMVEC(4)

-- GLES doesn't allow passing transposed matrices as uniforms
#ifdef GLES
#define MAT (adjoint m)
#define TRANS 0
#else
#define MAT m
#define TRANS 1
#endif

instance AsUniform (M22 GLfloat) where
  m `asUniform` loc = with MAT
                    $ glUniformMatrix2fv (getUL loc) 1 TRANS . castMatComponent

instance AsUniform (M33 GLfloat) where
  m `asUniform` loc = with MAT
                    $ glUniformMatrix3fv (getUL loc) 1 TRANS . castMatComponent

instance AsUniform (M44 GLfloat) where
  m `asUniform` loc = with MAT
                    $ glUniformMatrix4fv (getUL loc) 1 TRANS . castMatComponent

-- Support lists of vectors as uniform arrays of vectors.

#define UNIFORMARRAY_T(d,ht,glt) instance AsUniform [V##d ht] where {l `asUniform` loc = withArray l $ glUniform##d##glt##v (getUL loc) (fromIntegral $ length l) . castVecComponent}

#define UNIFORMARRAY(d) UNIFORMARRAY_T(d,GLint,i); UNIFORMARRAY_T(d,GLuint,ui); UNIFORMARRAY_T(d,GLfloat,f)

UNIFORMARRAY(1)
UNIFORMARRAY(2)
UNIFORMARRAY(3)
UNIFORMARRAY(4)
