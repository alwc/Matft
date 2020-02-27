//
//  data.swift
//  SuperMatft
//
//  Created by Junnosuke Kado on 2020/02/24.
//  Copyright © 2020 Junnosuke Kado. All rights reserved.
//

import Foundation

public struct MfData{
    public var _data: UnsafeMutableRawBufferPointer
    public var _shape: UnsafeMutableBufferPointer<Int>
    public var _strides: UnsafeMutableBufferPointer<Int>
    public var _mftype: MfType
    public var _size: Int
    public var _storedSize: Int
    
    public init(dataptr: UnsafeMutableRawBufferPointer, storedSize: Int, shapeptr: UnsafeMutableBufferPointer<Int>, mftype: MfType, stridesptr: UnsafeMutableBufferPointer<Int>? = nil){
        
        self._data = dataptr
        self._storedSize = storedSize
        self._shape = shapeptr
        self._size = shape2size(shapeptr)
        if let stridesptr = stridesptr{
            self._strides = stridesptr
        }
        else{
            self._strides = shape2strides(self._shape)
        }
        self._mftype = mftype
    }
    public init(mfdata: MfData){
        self._data = mfdata._data
        self._storedSize = mfdata._storedSize
        self._shape = mfdata._shape
        self._size = mfdata._size
        self._strides = mfdata._strides
        self._mftype = mfdata._mftype
    }
    
    internal func free() {
        self._data.deallocate()
        self._shape.deallocate()
        self._strides.deallocate()
    }
}

