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
                return [1, 2, 3, 4, 5, 6, 7, 8]
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
                                self.update(increaseZoom: false)
                            }
                    }
                )
                .gesture(MagnificationGesture()
                        .onChanged { state in
                            
                            self.zooming = true
                            
                            var adjustedState = state - self.previousZoomStageUpdateState
                            
                            if self.currentZoomStageIndex == 0 &&
                                adjustedState >= 1.05
                            {
                                adjustedState = 1.05
                            }
                            else if self.currentZoomStageIndex == GridZoomStages.zoomStages.count - 1 &&
                                        adjustedState <= 0.95
                            {
                                adjustedState = 0.95
                            }
                                
                            self.actualState = state
                            self.adjustedState = adjustedState
                            self.scale = adjustedState
                            
                            if adjustedState >= 1.3
                            {
                                self.previousZoomStageUpdateState = state - 1
                                self.update(increaseZoom: true)
                            }
                            else if adjustedState <= 0.7
                            {
                                self.previousZoomStageUpdateState = state - 1
                                self.update(increaseZoom: false)
                            }
                        }
                    .onEnded { _ in
                        self.zooming = false
                        self.scale = 1
                        self.previousZoomStageUpdateState = 0
                        self.adjustedState = 0
                    }
                )
            }
            .padding(.horizontal, 2)
            
            
            VStack(spacing: 5) {
                Text("Actual State: \(self.actualState)")
                Text("Adjusted State: \(self.adjustedState)")
                
                
                Text("Zoom Index: \(self.currentZoomStageIndex)")
                Text("Number of Items: \(GridZoomStages.getZoomStage(at: self.currentZoomStageIndex))")
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
            withAnimation {
                self.size = size
                
                self.scale = 1
                self.currentZoomStageIndex = newStageIndex
            }
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
