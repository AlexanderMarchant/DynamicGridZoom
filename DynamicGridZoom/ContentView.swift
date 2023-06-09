//
//  ContentView.swift
//  DynamicGridZoom
//
//  Created by Alex Marchant on 06/06/2023.
//

import SwiftUI

struct ContentView: View {
    let data = (1...300).map { "\($0)" }
    
    @State var scale: CGFloat = 1.0
    
    // Multiple of how much to decrease the existing size to equal the next decreased size
    @State var scaleFactor: CGFloat = 1.0
    
    // Multiple of how much to increase the existing size to equal the next increased size
    @State var zoomFactor: CGFloat = 1.0
    
    @State var isMagnifying = false
    
    @State private var size: CGFloat = 100
    
    @State private var currentZoomStageIndex = 2
    @State private var previousZoomStageUpdateState: CGFloat = 0
    @State private var adjustedState: CGFloat = 0
    
    @State private var gridWidth: CGFloat = 0
    @State private var zooming: Bool = false
    
    var body: some View {
        
        let columns = [
            GridItem(.adaptive(minimum: size), spacing: 2)
        ]
        
        return ScrollView {
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
                                self.calculateZoomFactor(at: self.currentZoomStageIndex)
                            }
                    }
                )
                .gesture(MagnificationGesture()
                        .onChanged { state in
                            
                            // Adjust state so we are always working from 1 because we are changing layouts whilst magnifying
                            var adjustedState = state - self.previousZoomStageUpdateState
                            
                            self.zooming = true
                            
                            // Decreasing the size
                            if scale <= 1,
                               adjustedState < 1
                            {
                                self.isMagnifying = false
                                if self.currentZoomStageIndex > GridZoomStages.zoomStages.count - 1
                                {
                                    if adjustedState > 0.95
                                    {
                                        self.scale = self.scaleFactor - (1 - adjustedState)
                                    }
                                    else
                                    {
                                        // If the user is at the upper limit of stages, cap the magnification
                                        adjustedState = 0.95
                                    }
                                }
                                else
                                {
                                    // Minimise the size of the elements based on the number of items to show per-line
                                    let updatedSize = self.calculateUpdatedSize(index: self.currentZoomStageIndex + 1)
                                    
                                    self.previousZoomStageUpdateState = state - 1
                                    
                                    self.zoomFactor = updatedSize / self.size
                                    self.scaleFactor = self.size / updatedSize
                                    
                                    // Setting the scale to the scale factor between sizes ensures the user doesn't see a 'jump' between stages
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
                                    if adjustedState < 1.1
                                    {
                                        self.scale = 1 - (1 - adjustedState)
                                    }
                                    else
                                    {
                                        // If the user is at the lower limit of stages, cap the magnification
                                        adjustedState = 1.1
                                    }
                                }
                                else
                                {
                                    self.currentZoomStageIndex = self.currentZoomStageIndex - 1
                                    self.previousZoomStageUpdateState = state - 1
                                    
                                    self.calculateZoomFactor(at: self.currentZoomStageIndex)
                                    
                                    self.scaleFactor = 1
                                    
                                    // Setting the scale 1 ensures the user doesn't see a 'jump' between zoomed stages
                                    self.scale = 1
                                }
                            }
                            else
                            {
                                if self.isMagnifying
                                {
                                    self.scale = 1 - (1 - adjustedState)
                                }
                                else
                                {
                                    self.scale = self.scaleFactor - (1 - adjustedState)
                                }
                            }
                            
                            self.adjustedState = adjustedState
                        }
                    .onEnded { _ in
                        
                        let shouldMagnify = self.adjustedState > 1
                        let animationDuration = 0.25
                        
                        withAnimation(.linear(duration: animationDuration))
                        {
                            if shouldMagnify
                            {
                                // Continue zooming until it reaches limit for the next stage
                                self.scale = self.zoomFactor
                            }
                            else
                            {
                                self.resetZoomVariables()
                            }
                        }
                        
                        if shouldMagnify
                        {
                            // Delay reset so zooming finishes and it smoothly transitions to the next zoom stage
                            // This mimics the behaviour a user see's if they were to manually transition between stages by zooming
                            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration)
                            {
                                if self.currentZoomStageIndex > 0
                                {
                                    self.currentZoomStageIndex = self.currentZoomStageIndex - 1
                                }
                                
                                self.resetZoomVariables()
                            }
                        }
                    }
                )
            }
            .padding(.horizontal, 2)
    }
    
    func resetZoomVariables()
    {
        self.calculateZoomFactor(at: self.currentZoomStageIndex)
        self.zooming = false
        self.scale = 1
        self.scaleFactor = 1
        self.previousZoomStageUpdateState = 0
        self.adjustedState = 0
    }
    
    func calculateUpdatedSize(index: Int) -> CGFloat
    {
        let zoomStages = GridZoomStages.getZoomStage(at: index)
        
        let availableSpace = self.gridWidth - (2 * CGFloat(zoomStages))
        
        return availableSpace / CGFloat(zoomStages)
    }
    
    func calculateZoomFactor(at index: Int)
    {
        let currentSize = self.calculateUpdatedSize(index: index)
        let magnifiedSize = self.calculateUpdatedSize(index: index - 1)
        
        self.zoomFactor = magnifiedSize / currentSize
        
        self.size = currentSize
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
