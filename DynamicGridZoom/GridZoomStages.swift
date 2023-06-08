//
//  GridZoomStages.swift
//  DynamicGridZoom
//
//  Created by Alex Marchant on 08/06/2023.
//

import SwiftUI

struct GridZoomStages
{
    static var zoomStages: [Int]
    {
        if UIDevice.current.userInterfaceIdiom == .pad
        {
            if UIDevice.current.orientation.isLandscape
            {
                return [4, 6, 10, 14, 18]
            }
            else
            {
                return [4, 6, 8, 10, 12]
            }
        }
        else
        {
            if UIDevice.current.orientation.isLandscape
            {
                return [4, 6, 8, 9]
            }
            else
            {
                return [1, 2, 4, 6, 8]
            }
        }
    }
    
    static func getZoomStage(at index: Int) -> Int
    {
        if index >= zoomStages.count
        {
            return zoomStages.last!
        }
        else if index < 0
        {
            return zoomStages.first!
        }
        else
        {
            return zoomStages[index]
        }
    }
}
