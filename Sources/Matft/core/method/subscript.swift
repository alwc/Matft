//
//  subscript.swift
//  Matft
//
//  Created by Junnosuke Kado on 2020/02/27.
//  Copyright © 2020 jkado. All rights reserved.
//

import Foundation
import Accelerate

extension MfArray: MfSubscriptable{
    public subscript(indices: Int...) -> Any{
        get {
            var indices: [Any] = indices
            let ret = self._get_mfarray(indices: &indices)

            if let scalar = ret.scalar{
                return scalar
            }
            else{
                return ret
            }
        }
        set(newValue){
            var indices: [Any] = indices
            
            if let newValue = newValue as? MfArray{
                return self._set_mfarray(indices: &indices, newValue: newValue)
            }
            else{
                return self._set_mfarray(indices: &indices, newValue: MfArray([newValue]))
            }
        }
    }
    public subscript(indices: MfSlice...) -> MfArray{
        get{
            var indices: [Any] = indices
            return self._get_mfarray(indices: &indices)
        }
        set(newValue){
            var indices: [Any] = indices
            return self._set_mfarray(indices: &indices, newValue: newValue)
        }
    }
    /*
    public subscript(indices: MfArray) -> MfArray{
        get{
            switch indices.mftype {
            case .Bool:
                preconditionFailure("Bool Getter is not supported now but will be supported future.")
            case .Int:
                preconditionFailure("Int is not supported now but will be supported future.")
            default:
                preconditionFailure("indices must be Bool or Int, but got \(indices.mftype)")
            }
            
        }
        set(newValue){
            switch indices.mftype {
            case .Bool:
                precondition(indices.shape == self.shape, "masked mfarray must be same shape")
                /*
                 >>> a = np.array([1,2])
                 >>> b = a[0]
                 >>> b
                 1
                 >>> a[np.array([True, True])] = 555
                 >>> a
                 array([555, 555])
                 >>> b
                 1
                 */
                let ret = !indices * self + indices * newValue
                switch self.storedType {
                case .Float:
                    _ = copy_mfarray(ret, dsttmpMfarray: self, cblas_func: cblas_scopy)
                case .Double:
                    _ = copy_mfarray(ret, dsttmpMfarray: self, cblas_func: cblas_dcopy)
                }
            case .Int:
                preconditionFailure("Int is not supported now but will be supported future.")
            default:
                preconditionFailure("indices must be Bool or Int, but got \(indices.mftype)")
            }
            
        }
    }
    */
    //public subscript<T: MfSlicable>(indices: T...) -> MfArray{
    public subscript(indices: Any...) -> MfArray{
        get{
            var indices = indices
            return self._get_mfarray(indices: &indices)
        }
        set(newValue){
            var indices = indices
            self._set_mfarray(indices: &indices, newValue: newValue)
        }
    }
    
    /*
    public subscript(indices: [Int]) -> Any{
        
        get{
            var indices = indices
            precondition(indices.count == self.ndim, "cannot return value because given indices were invalid")
            let flattenIndex = self.withStridesUnsafeMBPtr{
                stridesptr in
                indices.withUnsafeMutableBufferPointer{
                    _inner_product($0, stridesptr)
                }
            }

            precondition(flattenIndex < self.size, "indices \(indices) is out of bounds")
            if self.mftype == .Double{
                return self.data[flattenIndex]
            }
            else{
                return self.data[flattenIndex]
            }
        }
        set(newValue){
            var indices = indices
            precondition(indices.count == self.ndim, "cannot return value because given indices were invalid")
            let flattenIndex = self.withStridesUnsafeMBPtr{
                stridesptr in
                indices.withUnsafeMutableBufferPointer{
                    _inner_product($0, stridesptr)
                }
            }
            
            precondition(flattenIndex < self.size, "indices \(indices) is out of bounds")
            if let newValue = newValue as? Double{
                self.withDataUnsafeMBPtrT(datatype: Double.self){
                    $0[flattenIndex] = newValue
                }
            }
            else if let newValue = newValue as? UInt8{
                self.withDataUnsafeMBPtrT(datatype: Float.self){
                    $0[flattenIndex] = Float(newValue)
                }
            }
            else if let newValue = newValue as? UInt16{
                self.withDataUnsafeMBPtrT(datatype: Float.self){
                    $0[flattenIndex] = Float(newValue)
                }
            }
            else if let newValue = newValue as? UInt32{
                self.withDataUnsafeMBPtrT(datatype: Float.self){
                    $0[flattenIndex] = Float(newValue)
                }
            }
            else if let newValue = newValue as? UInt64{
                self.withDataUnsafeMBPtrT(datatype: Float.self){
                    $0[flattenIndex] = Float(newValue)
                }
            }
            else if let newValue = newValue as? UInt{
                self.withDataUnsafeMBPtrT(datatype: Float.self){
                    $0[flattenIndex] = Float(newValue)
                }
            }
            else if let newValue = newValue as? Int8{
                self.withDataUnsafeMBPtrT(datatype: Float.self){
                    $0[flattenIndex] = Float(newValue)
                }
            }
            else if let newValue = newValue as? Int16{
                self.withDataUnsafeMBPtrT(datatype: Float.self){
                    $0[flattenIndex] = Float(newValue)
                }
            }
            else if let newValue = newValue as? Int32{
                self.withDataUnsafeMBPtrT(datatype: Float.self){
                    $0[flattenIndex] = Float(newValue)
                }
            }
            else if let newValue = newValue as? Int64{
                self.withDataUnsafeMBPtrT(datatype: Float.self){
                    $0[flattenIndex] = Float(newValue)
                }
            }
            else if let newValue = newValue as? Int{
                self.withDataUnsafeMBPtrT(datatype: Float.self){
                    $0[flattenIndex] = Float(newValue)
                }
            }
            else if let newValue = newValue as? Float{
                self.withDataUnsafeMBPtrT(datatype: Float.self){
                    $0[flattenIndex] = Float(newValue)
                }
            }
            else{
                fatalError("Unsupported type was input")
            }
        }
        
    }*/
    //Use opaque?
    private func _get_mfarray(indices: inout [Any]) -> MfArray{
        precondition(indices.count <= self.ndim, "cannot return value because given indices were too many")

        // supplement insufficient slices
        if indices.count < self.ndim{
            for _ in 0..<self.ndim - indices.count{
                indices.append(MfSlice())
            }
        }
        
        var orig_axis = 0
        var new_axis = 0
        var newshape: [Int] = []
        var newstrides: [Int] = []
        var newsize = 1
        
        var offset = self.offsetIndex
        self.withShapeStridesUnsafeMBPtr{
        [unowned self] (orig_shapeptr, orig_stridesptr) in
            //Indexing ref: https://docs.scipy.org/doc/numpy/reference/arrays.indexing.html
            while orig_axis < self.ndim {
                if let _index = indices[orig_axis] as? Int { // normal indexing
                    let index = get_index(_index, dim: orig_shapeptr[orig_axis], axis: orig_axis)

                    offset += index * orig_stridesptr[orig_axis]
                    orig_axis += 1 // not move
                    new_axis += 0
                }
                else if let mfslice = indices[orig_axis] as? MfSlice{// slicing
                    let orig_dim = orig_shapeptr[orig_axis]
                    //default value is 0(if by >= 0), dim - 1(if by < 0)
                    var startIndex = mfslice.start ?? (mfslice.by >= 0 ? 0 : orig_dim - 1)
                    //default value is dim(if by >= 0), -dim - 1(if by < 0)
                    var toIndex = mfslice.to ?? (mfslice.by >= 0 ? orig_dim : -orig_dim - 1)
                    var by = mfslice.by
                    /*
                    align with proper value
                    by > 0
                    startIndex <= -orig_dim ==> 0
                    startIndex > orig_dim ==> orig_dim
                    orig_dim < toIndex ==> orig_dim
                    toIndex <= -orig_dim ==> 0
                    
                    by < 0
                    startIndex < -orig_dim ==> -orig_dim-1
                    startIndex > orig_dim ==> orig_dim
                    orig_dim < toIndex ==> orig_dim
                    toIndex < -orig_dim ==> -orig_dim-1
                    */
                    if by >= 0{
                        if startIndex <= -orig_dim{
                            startIndex = 0
                        }
                        else if startIndex > orig_dim{
                            startIndex = orig_dim
                        }
                        if orig_dim < toIndex{
                            toIndex = orig_dim
                        }
                        else if toIndex < -orig_dim{
                            toIndex = 0
                        }
                    }
                    else{
                        if startIndex < -orig_dim{
                            startIndex = -orig_dim - 1
                        }
                        else if startIndex > orig_dim{
                            startIndex = orig_dim
                        }
                        if orig_dim < toIndex{
                            toIndex = orig_dim
                        }
                        else if toIndex < -orig_dim{
                            toIndex = -orig_dim - 1
                        }
                    }
                     
                    // convert negative index to proper positive index
                    startIndex = startIndex >= 0 ? startIndex : orig_dim + startIndex
                    toIndex = toIndex >= 0 ? toIndex : orig_dim + toIndex
                    
                    var nsteps = (toIndex - startIndex) / mfslice.by + (toIndex - startIndex) % mfslice.by
                    if nsteps <= 0{
                        nsteps = 0
                        by = 1
                        startIndex = 0
                    }
                     
                    newshape.append(Swift.min(nsteps, orig_dim))
                    newstrides.append(orig_stridesptr[orig_axis] * by)
                    newsize *= newshape.last!
                    offset += startIndex * orig_stridesptr[orig_axis]
                    
                    orig_axis += 1
                    new_axis += 1
                }
                else if let subop = indices[orig_axis] as? SubscriptOps{// expand dim
                    switch subop {
                    case .newaxis:
                        newshape.append(1)
                        newstrides.append(0)
                    /*
                    default:
                        fatalError("\(subop) is invalid in getter")*/
                    }
                    
                    orig_axis += 0 // not move
                    new_axis += 1
                }
                else{
                    preconditionFailure("\(indices[orig_axis]) is not subscriptable value")
                }
            }
        }
        let newndim = newshape.count
        
        let newstructure = withDummyShapeStridesMBPtr(newndim){
            newshapeptr, newstridesptr in
            //move shape
            newshape.withUnsafeMutableBufferPointer{
                newshapeptr.baseAddress!.moveAssign(from: $0.baseAddress!, count: newndim)
            }
            
            //move strides
            newstrides.withUnsafeMutableBufferPointer{
                newstridesptr.baseAddress!.moveAssign(from: $0.baseAddress!, count: newndim)
            }
        }
        //newarray.mfdata._storedSize = get_storedSize(newarray.shapeptr, newarray.stridesptr)
        //print(newarray.shape, newarray.mfdata._size, newarray.mfdata._storedSize)
        return MfArray(base: self, mfstructure: newstructure, offset: offset)
    }
    
    private func _set_mfarray(indices: inout [Any], newValue: MfArray){
        for index in indices{
            if let _ = index as? SubscriptOps{
                fatalError("SubscriptOps must not be passed to setter")
            }
        }
        
        //note that this function is alike _binary_operation
        let array = self._get_mfarray(indices: &indices)
        var newValue = newValue

        if array.mftype != newValue.mftype{
            newValue = newValue.astype(array.mftype)
        }
        //TODO: refactor
        if (array.size == newValue.size && array.size == 1){
            switch array.storedType {
            case .Float:
                array.withDataUnsafeMBPtrT(datatype: Float.self){
                    dstptr in
                    newValue.withDataUnsafeMBPtrT(datatype: Float.self){
                        dstptr.baseAddress!.pointee = $0.baseAddress!.pointee
                    }
                }
            case .Double:
                array.withDataUnsafeMBPtrT(datatype: Double.self){
                    dstptr in
                    newValue.withDataUnsafeMBPtrT(datatype: Double.self){
                        dstptr.baseAddress!.pointee = $0.baseAddress!.pointee
                    }
                }
            }
            return
        }
        if array.shape != newValue.shape{
            newValue = newValue.broadcast_to(shape: array.shape)
        }
        
        switch array.storedType {
        case .Float:
            _ = copy_mfarray(newValue, dsttmpMfarray: array, cblas_func: cblas_scopy)
        case .Double:
            _ = copy_mfarray(newValue, dsttmpMfarray: array, cblas_func: cblas_dcopy)
        }
    }
    
    // fancy indexing
    // note that if not assignment, returned copy value not view.
    /*
     >>> a = np.arange(9).reshape(3,3)
     >>> a
     array([[0, 1, 2],
            [3, 4, 5],
            [6, 7, 8]])
     >>> a[[1,2],[2,2]].base
     None
     */
    /*
    private func _get_mfarray(indices: MfArray) -> MfArray{
        precondition(indices.mftype == .Int, "indices must be int, but got \(indices.mftype)")
        // same as get_index function
        let ind = (-indices.sign()).clip(min: 0) * MfArray(Array(self.shape.prefix(indices.ndim))) // get_index
        let offset = (ind * MfArray(Array(self.strides.prefix(indices.ndim)))).sum(axis: -1, keepDims: true) // index * orig_stridesptr[orig_axis]
        

        
        var orig_axis = 0
        let orig_shape = self.shape
        let orig_strides = self.strides
        
        for _ in 0..<indices.ndim{
            
        }
        
        let index = get_index(_index, dim: orig_shapeptr[orig_axis], axis: orig_axis)

        offset += index * orig_stridesptr[orig_axis]
        orig_axis += 1 // not move
        new_axis += 0
    }*/
}

fileprivate func _inner_product(_ left: UnsafeMutableBufferPointer<Int>, _ right: UnsafeMutableBufferPointer<Int>) -> Int{
    
    assert(left.count == right.count, "cannot calculate inner product due to unsame dim")
    
    return zip(left, right).map(*).reduce(0, +)
}
