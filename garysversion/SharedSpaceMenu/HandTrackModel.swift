//
//  HandTrackModel.swift
//  SharedSpaceMenu
//
//  Created by Gary Yao on 3/30/24.
//

import Foundation
import ARKit
import RealityKit
class HandTracking{
    let handDetection = HandTrackingProvider()
    var arkitSession = ARKitSession()
    var time_tick = 0
    var last_presnap = -100
    var running = true
    var ball = ModelEntity()
    var fireballModel = FireViewModel()
    var root = Entity()
    @Published var fire = false
    @MainActor
    init() {
    }
    
    func processHandAnchorUpdates() async{
        await run(function: self.queryAndProcessLatestHandAnchor, withFrequency: 60)
    }
    
    @MainActor
    func runARKitSession() async {
        do {
            try await arkitSession.run([handDetection])
        } catch {
            fatalError("arkit start failed")
        }
    }
    
    @MainActor
    func queryAndProcessLatestHandAnchor(){
        time_tick += 1
        print(time_tick)
        
        enum HandState{
            case rest
            case presnap
            case aftersnap
        }
        
        if let lh = handDetection.latestAnchors.leftHand{
            if fire{
                print("addingfire ")
                let indextip = lh.handSkeleton!.joint(.indexFingerTip)
                let indextiploc = getlocation(jointloc: lh.originFromAnchorTransform, parentloc: indextip.anchorFromJointTransform)
                let a = indextiploc
                fireballModel.myball.transform.translation = SIMD3(x: a.x, y: a.y + 0.07, z: a.z)
            }
            if preSnap(lefthand: lh){
                last_presnap = time_tick
                print("Presnap")
            }
            if afterSnap(lefthand: lh){
                print("afterSnap")
                if time_tick - last_presnap < 10{
                    print("Snap Detected")
                    fireballModel.myfireball.state = .holding
                    fire = true
                }
            }
            if fire && pointing(lefthand: lh){
                print("pointing")
                fire = false
                //enum: tos transform
                //input
                fireballModel.myball.move(to: Transform(translation: SIMD3(x: 0.0, y: 0.0, z: -3.0)), relativeTo: ball, duration: 3)
                fireballModel.myfireball.state = .thrown
                //ball.move(to: Transform(translation: SIMD3(x: 0.0, y: 0.0, z: -3.0)), relativeTo: ball, duration: 3)
               // ball.move(to: Transform(translation: SIMD3(x: 0.0, y: 0.0, z: -3.0)), relativeTo: nil),du)
            }
        }
    }
    
    func getlocation(jointloc:simd_float4x4, parentloc:simd_float4x4) -> simd_float4{
        return(matrix_multiply(jointloc, parentloc).columns.3)
    }
    
    func pointing(lefthand:HandAnchor) -> Bool{
        guard
            let indextip  = lefthand.handSkeleton?.joint(.indexFingerTip),
            let indexknuckle = lefthand.handSkeleton?.joint(.indexFingerKnuckle),
            let middletip = lefthand.handSkeleton?.joint(.middleFingerTip),
            let middleknuckle = lefthand.handSkeleton?.joint(.middleFingerKnuckle),
            let thumbtip = lefthand.handSkeleton?.joint(.thumbTip),
            let thumbknuckle = lefthand.handSkeleton?.joint(.thumbKnuckle),
            let forearm = lefthand.handSkeleton?.joint(.forearmArm),
            let wrist = lefthand.handSkeleton?.joint(.wrist)
        else{
            return false
        }
        let lefthandanchor = lefthand.originFromAnchorTransform
        let indextiploc = getlocation(jointloc: lefthandanchor, parentloc: indextip.anchorFromJointTransform)
        let indexknuckleloc = getlocation(jointloc: lefthandanchor, parentloc: indexknuckle.anchorFromJointTransform)
        
        let middletiploc = getlocation(jointloc: lefthandanchor, parentloc: middletip.anchorFromJointTransform)
        let middleknuckleloc = getlocation(jointloc: lefthandanchor, parentloc: middleknuckle.anchorFromJointTransform)
        let thumbtiploc = getlocation(jointloc: lefthandanchor, parentloc: thumbtip.anchorFromJointTransform)
        let thumbknuckleloc = getlocation(jointloc: lefthandanchor, parentloc: thumbknuckle.anchorFromJointTransform)
        let forearmloc = getlocation(jointloc: lefthandanchor, parentloc: forearm.anchorFromJointTransform)
        let wristloc = getlocation(jointloc: lefthandanchor, parentloc: wrist.anchorFromJointTransform)
        
        if indextiploc.y - indexknuckleloc.y < 0.01{
            return true
        }
        return false
    }
    
    func preSnap(lefthand:HandAnchor) -> Bool{
        guard
            let indextip = lefthand.handSkeleton?.joint(.indexFingerTip),
            let indexknuckle = lefthand.handSkeleton?.joint(.indexFingerKnuckle),
            let middletip = lefthand.handSkeleton?.joint(.middleFingerTip),
            let middleknuckle = lefthand.handSkeleton?.joint(.middleFingerKnuckle),
            let thumbtip = lefthand.handSkeleton?.joint(.thumbTip),
            let thumbknuckle = lefthand.handSkeleton?.joint(.thumbKnuckle),
            let forearm = lefthand.handSkeleton?.joint(.forearmArm),
            let wrist = lefthand.handSkeleton?.joint(.wrist)
        else{
            return false
        }
        let lefthandanchor = lefthand.originFromAnchorTransform
        let indextiploc = getlocation(jointloc: lefthandanchor, parentloc: indextip.anchorFromJointTransform)
        let indexknuckleloc = getlocation(jointloc: lefthandanchor, parentloc: indexknuckle.anchorFromJointTransform)
        
        let middletiploc = getlocation(jointloc: lefthandanchor, parentloc: middletip.anchorFromJointTransform)
        let middleknuckleloc = getlocation(jointloc: lefthandanchor, parentloc: middleknuckle.anchorFromJointTransform)
        let thumbtiploc = getlocation(jointloc: lefthandanchor, parentloc: thumbtip.anchorFromJointTransform)
        let thumbknuckleloc = getlocation(jointloc: lefthandanchor, parentloc: thumbknuckle.anchorFromJointTransform)
        let forearmloc = getlocation(jointloc: lefthandanchor, parentloc: forearm.anchorFromJointTransform)
        let wristloc = getlocation(jointloc: lefthandanchor, parentloc: wrist.anchorFromJointTransform)
        
        let distance_middle_index = distance(middletiploc, thumbtiploc)
        return distance_middle_index < 0.02
    }
    
    func afterSnap(lefthand:HandAnchor) -> Bool{
        guard
            let indextip = lefthand.handSkeleton?.joint(.indexFingerTip),
            let indexknuckle = lefthand.handSkeleton?.joint(.indexFingerKnuckle),
            let middletip = lefthand.handSkeleton?.joint(.middleFingerTip),
            let middleknuckle = lefthand.handSkeleton?.joint(.middleFingerKnuckle),
            let thumbtip = lefthand.handSkeleton?.joint(.thumbTip),
            let thumbknuckle = lefthand.handSkeleton?.joint(.thumbKnuckle),
            let forearm = lefthand.handSkeleton?.joint(.forearmArm),
            let wrist = lefthand.handSkeleton?.joint(.wrist)
        else{
            return false
        }
        let lefthandanchor = lefthand.originFromAnchorTransform
        let indextiploc = getlocation(jointloc: lefthandanchor, parentloc: indextip.anchorFromJointTransform)
        let indexknuckleloc = getlocation(jointloc: lefthandanchor, parentloc: indexknuckle.anchorFromJointTransform)
        
        let middletiploc = getlocation(jointloc: lefthandanchor, parentloc: middletip.anchorFromJointTransform)
        let middleknuckleloc = getlocation(jointloc: lefthandanchor, parentloc: middleknuckle.anchorFromJointTransform)
        let thumbtiploc = getlocation(jointloc: lefthandanchor, parentloc: thumbtip.anchorFromJointTransform)
        let thumbknuckleloc = getlocation(jointloc: lefthandanchor, parentloc: thumbknuckle.anchorFromJointTransform)
        let forearmloc = getlocation(jointloc: lefthandanchor, parentloc: forearm.anchorFromJointTransform)
        let wristloc = getlocation(jointloc: lefthandanchor, parentloc: wrist.anchorFromJointTransform)
        
        let distance_middle_index = distance(middletiploc, thumbknuckleloc)
        return distance_middle_index < 0.05
    }
    
    
    
    @MainActor
    func run(function: () async -> Void, withFrequency hz: UInt64) async {
        while true {
            if !running{
                return
            }
            if Task.isCancelled {
                return
            }
            
            // Sleep for 1 s / hz before calling the function.
            let nanoSecondsToSleep: UInt64 = NSEC_PER_SEC / hz
            do {
                try await Task.sleep(nanoseconds: nanoSecondsToSleep)
            } catch {
                // Sleep fails when the Task is cancelled. Exit the loop.
                return
            }
            await function()
        }
    }
    
}
