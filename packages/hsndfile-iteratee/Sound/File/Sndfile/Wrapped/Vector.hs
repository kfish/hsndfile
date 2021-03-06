{-# LANGUAGE MultiParamTypeClasses
           , GeneralizedNewtypeDeriving
           , FlexibleInstances
           , ScopedTypeVariables
           , TypeSynonymInstances #-}

module Sound.File.Sndfile.Wrapped.Vector (
    Vector(..)
  , StorableVector
) where

import           Control.Monad
import           Data.Iteratee.Base.LooseMap
import qualified Data.Iteratee.Base.StreamChunk as SC
import qualified Data.Vector.Generic as V
import qualified Data.Vector.Generic.Mutable as MV
import qualified Data.Vector.Storable as SV
import qualified Data.ListLike as LL
import           Data.Monoid
import           Foreign.ForeignPtr
import           Foreign.Marshal.Array
import           Foreign.Ptr
import           Foreign.Storable
import           Sound.File.Sndfile.Buffer

-- |Wrap a Data.Vector.Vector
newtype Vector v a = Vector { unWrap :: v a }
type StorableVector = Vector SV.Vector

wrap :: v a -> Vector v a
{-# INLINE wrap #-}
wrap = Vector

instance V.Vector v a => Monoid (Vector v a) where
    mempty        = wrap V.empty
    mappend a1 a2 = wrap (unWrap a1 V.++ unWrap a2)

instance V.Vector v a => LL.FoldableLL (Vector v a) a where
    foldl f z  = V.foldl f z . unWrap
    foldl' f z = V.foldl' f z . unWrap
    foldl1 f   = V.foldl1 f . unWrap
    foldr f z  = V.foldr f z . unWrap
    foldr1 f   = V.foldr1 f . unWrap

instance V.Vector v a => LL.ListLike (Vector v a) a where
    length        = V.length . unWrap
    null          = V.null . unWrap
    singleton     = wrap . V.singleton
    cons a        = wrap . V.cons a . unWrap
    head          = V.head . unWrap
    tail          = wrap . V.tail . unWrap
    findIndex p   = V.findIndex p . unWrap
    splitAt i s   = let v  = unWrap s
                        a1 = V.take i v
                        a2 = V.drop i v
                    in (Vector a1, Vector a2)
    dropWhile p   = wrap . V.dropWhile p . unWrap
    fromList      = wrap . V.fromList
    toList        = V.toList . unWrap
    rigidMap f    = wrap . V.map f . unWrap

instance (V.Vector v el, V.Vector v el') => LooseMap (Vector v) el el' where
    looseMap f = wrap . V.map f . unWrap

vmap :: (V.Vector v el, SC.StreamChunk s' el') => (el -> el') -> Vector v el -> s' el'
vmap f xs = step xs
  where
      step bs
        | SC.null bs = mempty
        | True       = f (SC.head bs) `SC.cons` step (SC.tail bs)

instance (V.Vector v a) => SC.StreamChunk (Vector v) a where
    cMap = vmap

-- | Create a Vector from a pointer and an element count.
createCopySV :: (Storable el) => Ptr el -> Int -> IO (SV.Vector el)
createCopySV p n = do
    mv@(SV.MVector _ _ fp) <- MV.unsafeNew n
    withForeignPtr fp $ \newp -> copyArray newp p n
    V.unsafeFreeze mv

instance Storable el => SC.ReadableChunk StorableVector el where
    readFromPtr p l | rem l s == 0 = wrap `fmap` createCopySV p n
                    | otherwise    = error $ "ReadableChunk.readFromPtr (Sound.File.Sndfile.Wrapped.Vector.Vector): invalid number of bytes: " ++ show l ++ " size: " ++ show s
        where s = sizeOf (undefined :: el)
              n = l `div` s
