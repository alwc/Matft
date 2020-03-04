//
//  conversion.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/26.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

extension Matft.mfarray{
    public static func astype(_ mfarray: MfArray, mftype: MfType) -> MfArray{
        //let newarray = Matft.mfarray.shallowcopy(mfarray)
        //newarray.mfdata._mftype = mftype
        let newdata = mfarray.mfdata.astype(mftype)
        return MfArray(mfdata: newdata)
    }
    
    public static func transpose(_ mfarray: MfArray, axes: [Int]? = nil) -> MfArray{
        var permutation: [Int] = [], reverse_permutation: [Int] = []
        let ndim =  mfarray.shape.count
        
        let newarray = Matft.mfarray.shallowcopy(mfarray)
        
        if let axes = axes{
            precondition(axes.count == ndim, "axes don't match array")
            for _ in 0..<ndim{
                reverse_permutation.append(-1)
            }
            for i in 0..<ndim{
                let axis = axes[i]
                precondition(axis < ndim, "invalid axes")
                precondition(reverse_permutation[axis] == -1, "repeated axis in transpose")
                reverse_permutation[axis] = i
                permutation.append(axis)
            }
        }
        else {
            for i in 0..<ndim{
                permutation.append(ndim - 1 - i)
            }
        }
        
        for i in 0..<ndim{
            newarray.shapeptr[i] = mfarray.shapeptr[permutation[i]]
            newarray.stridesptr[i] = mfarray.stridesptr[permutation[i]]
        }
        
        return newarray
    }
    
    public static func broadcast_to(_ mfarray: MfArray, shape: [Int]) throws -> MfArray{
        var shape = shape
        let newarray = Matft.mfarray.shallowcopy(mfarray)
        newarray.mfdata._shape.assign(from: &shape, count: shape.count)
        newarray.mfdata._ndim = shape2ndim(&shape)
        newarray.mfdata._size = shape2size(&shape)
        
        let idim_start = newarray.ndim  - mfarray.ndim
        
        
        if idim_start < 0{
            throw MfError.conversionError("can't broadcast to fewer dimensions")
        }
        
        for idim in (idim_start..<newarray.ndim ).reversed(){
            let strides_shape_value = mfarray.shape[idim - idim_start]
            /* If it doesn't have dimension one, it must match */
            if strides_shape_value == 1{
                newarray.stridesptr[idim] = 0
            }
            else if strides_shape_value != shape[idim]{
                throw MfError.conversionError("could not broadcast from shape \(mfarray.ndim), \(mfarray.shape) into shape \(newarray.ndim), \(shape)")
            }
            else{
                newarray.stridesptr[idim] = mfarray.stridesptr[idim - idim_start]
            }
        }
        
        /* New dimensions get a zero stride */
        for idim in 0..<idim_start{
            newarray.stridesptr[idim] = 0
        }
        
        return newarray
    }
}

extension Matft.mfarray.mfdata{
    public static func astype(_ mfdata: MfData, mftype: MfType) -> MfData{
        
        let newStoredType = MfType.storedType(mftype)
        if mfdata._storedType == newStoredType{
            return mfdata.deepcopy()
        }
        
        //copy shape
        let shapeptr = create_unsafeMPtrT(type: Int.self, count: mfdata._ndim)
        shapeptr.assign(from: mfdata._shape, count: mfdata._ndim)
        
        //copy strides
        let stridesptr = create_unsafeMPtrT(type: Int.self, count: mfdata._ndim)
        stridesptr.assign(from: mfdata._strides, count: mfdata._ndim)
        
        switch newStoredType{
        case .Float://double to float
            let ptrD = mfdata._data.bindMemory(to: Double.self, capacity: mfdata._storedSize)
            let ptrF = create_unsafeMPtrT(type: Float.self, count: mfdata._storedSize)
            
            unsafePtrT2UnsafeMPtrU(ptrD, ptrF, vDSP_vdpsp, mfdata._storedSize)
            
            let dataptr = UnsafeMutableRawPointer(ptrF)
            
            return MfData(dataptr: dataptr, storedSize: mfdata._storedSize, shapeptr: shapeptr, mftype: mftype, ndim: mfdata._ndim, stridesptr: stridesptr)
            
        case .Double://float to double
            let ptrF = mfdata._data.bindMemory(to: Float.self, capacity: mfdata._storedSize)
            let ptrD = create_unsafeMPtrT(type: Double.self, count: mfdata._storedSize)
            
            unsafePtrT2UnsafeMPtrU(ptrF, ptrD, vDSP_vspdp, mfdata._storedSize)

            let dataptr = UnsafeMutableRawPointer(ptrD)

            return MfData(dataptr: dataptr, storedSize: mfdata._storedSize, shapeptr: shapeptr, mftype: mftype, ndim: mfdata._ndim, stridesptr: stridesptr)
        }
    }
}
