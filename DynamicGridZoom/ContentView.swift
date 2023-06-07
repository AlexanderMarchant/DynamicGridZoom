//
//  ContentView.swift
//  DynamicGridZoom
//
//  Created by Alex Marchant on 06/06/2023.
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

struct ContentView: View {
    let data = (1...300).map { "\($0)" }
    
    @State var scale: CGFloat = 1.0
    @State var scaleFactor: CGFloat = 1.0
    @State var zoomFactor: CGFloat = 1.0
    
    @State var isMagnifying = false
    
    @State private var size: CGFloat = 100
    
    @State private var currentZoomStageIndex = 2
    @State private var previousZoomStageUpdateState: CGFloat = 0
    @State private var actualState: CGFloat = 0
    @State private var adjustedState: CGFloat = 0
    
    @State private var gridWidth: CGFloat = 0
    @State private var zooming: Bool = false
    
    var body: some View {
        
        var columns = [
            GridItem(.adaptive(minimum: size), spacing: 2)
        ]
        
        return ZStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(data, id: \.self) { item in
                        GridCell(item: item, size: size)
                    }
                }
                .scrollDisabled(self.zooming)
                .scaleEffect(scale, anchor: .top)
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                self.gridWidth = proxy.frame(in: .local).width
                                
                                let zoomStages = GridZoomStages.getZoomStage(at: self.currentZoomStageIndex)
                                
                                let availableSpace = self.gridWidth - (2 * CGFloat(zoomStages))
                                
                                let updatedSize = availableSpace / CGFloat(zoomStages)
                                
                                self.size = updatedSize
                                
                                
                                let zoomStages1 = GridZoomStages.getZoomStage(at: self.currentZoomStageIndex - 1)
                                
                                let updatedSize1 = availableSpace / CGFloat(zoomStages1)
                                
                                self.zoomFactor = updatedSize1 / updatedSize
                            }
                    }
                )
                .gesture(MagnificationGesture()
                        .onChanged { state in
                            
                            self.zooming = true
                            
                            var adjustedState = state - self.previousZoomStageUpdateState
                            
                            // Decreasing the size
                            if scale <= 1,
                               adjustedState < 1
                            {
                                self.isMagnifying = false
                                if self.currentZoomStageIndex > GridZoomStages.zoomStages.count - 1
                                {
                                    if adjustedState >= 0.95
                                    {
                                        self.scale = self.scaleFactor - (1 - adjustedState)
                                    }
                                }
                                else
                                {
                                    let zoomStages = GridZoomStages.getZoomStage(at: self.currentZoomStageIndex + 1)
                                    
                                    let availableSpace = self.gridWidth - (2 * CGFloat(zoomStages))
                                    
                                    let updatedSize = availableSpace / CGFloat(zoomStages)
                                    
                                    self.previousZoomStageUpdateState = state - 1
                                    self.zoomFactor = updatedSize / self.size
                                    self.scaleFactor = self.size / updatedSize
                                    self.scale = self.scaleFactor
                                    self.size = updatedSize
                                    self.currentZoomStageIndex = self.currentZoomStageIndex + 1
                                }
                            }
                            // Increasing the size
                            else if scale >= self.zoomFactor,
                                    adjustedState > 1
                            {
                                self.isMagnifying = true
                                if self.currentZoomStageIndex == 0
                                {
                                    if adjustedState <= 1.05
                                    {
                                        self.scale = self.scaleFactor - (1 - adjustedState)
                                    }
                                }
                                else
                                {
                                    let zoomStages = GridZoomStages.getZoomStage(at: self.currentZoomStageIndex - 1)
                                    
                                    let availableSpace = self.gridWidth - (2 * CGFloat(zoomStages))
                                    
                                    let updatedSize = availableSpace / CGFloat(zoomStages)
                                    
                                    let zoomStages1 = GridZoomStages.getZoomStage(at: self.currentZoomStageIndex - 2)
                                    
                                    let availableSpace1 = self.gridWidth - (2 * CGFloat(zoomStages1))
                                    
                                    let nextSize = availableSpace1 / CGFloat(zoomStages1)
                                    
                                    self.previousZoomStageUpdateState = state - 1
                                    self.zoomFactor = nextSize / updatedSize
                                    self.scaleFactor = 1
                                    self.scale = 1
                                    self.size = updatedSize
                                    self.currentZoomStageIndex = self.currentZoomStageIndex - 1
                                }
                            }
                            else
                            {
                                self.scale = self.scaleFactor - (1 - adjustedState)
                            }
                            
                                
                            self.actualState = state
                            self.adjustedState = adjustedState
                        }
                    .onEnded { _ in
//                        if self.scale >= 1
//                        {
//                            let zoomStages = GridZoomStages.getZoomStage(at: self.currentZoomStageIndex - 1)
//                            
//                            let availableSpace = self.gridWidth - (2 * CGFloat(zoomStages))
//                            
//                            let updatedSize = availableSpace / CGFloat(zoomStages)
//                            self.size = updatedSize
//                            self.currentZoomStageIndex = self.currentZoomStageIndex - 1
//                        }
//                        else if self.scale <= scaleFactor
//                        {
//                            let zoomStages = GridZoomStages.getZoomStage(at: self.currentZoomStageIndex + 1)
//                            
//                            let availableSpace = self.gridWidth - (2 * CGFloat(zoomStages))
//                            
//                            let updatedSize = availableSpace / CGFloat(zoomStages)
//                            self.size = updatedSize
//                            self.currentZoomStageIndex = self.currentZoomStageIndex + 1
//                        }
                        
                        withAnimation
                        {
                            self.zooming = false
                            self.scale = 1
                            self.scaleFactor = 1
                            self.zoomFactor = 1
                            self.previousZoomStageUpdateState = 0
                            self.adjustedState = 0
                        }
                    }
                )
            }
            .padding(.horizontal, 2)
            
            
            VStack(spacing: 5) {
                Text("Actual State: \(self.actualState)")
                Text("Adjusted State: \(self.adjustedState)")
                
                Text("Scale: \(self.scale)")
                
                Text("Scale Factor: \(self.scaleFactor)")
                Text("Zoom Factor: \(self.zoomFactor)")
                
//                Text("Zoom Index: \(self.currentZoomStageIndex)")
//                Text("Number of Items: \(GridZoomStages.getZoomStage(at: self.currentZoomStageIndex))")
            }
            .padding(8)
            .background(Color.white.opacity(0.85))
            .cornerRadius(5)
            .shadow(color: .black.opacity(0.5), radius: 3)
        }
    }
    
    func update(increaseZoom: Bool?)
    {
        let newStageIndex = increaseZoom == nil ? self.currentZoomStageIndex : increaseZoom == true ? max(0, self.currentZoomStageIndex - 1) : self.currentZoomStageIndex + 1
        
        let zoomStages = GridZoomStages.getZoomStage(at: newStageIndex)
        
        let availableSpace = self.gridWidth - (2 * CGFloat(zoomStages))
        
        let size = availableSpace / CGFloat(zoomStages)
        
        DispatchQueue.main.async
        {
            // Performance starts to take a hit at 6/7 items displayed with very simple views
            // Disabling animations improves this
//            withAnimation {
//                self.size = size
//                self.currentZoomStageIndex = newStageIndex
//            }
        }
    }
}

struct GridCell: View {
    
    let item: String
    let size: CGFloat
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .frame(height: size)
                .foregroundColor(.blue)
            Text("\(item)")
                .foregroundColor(.white)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
