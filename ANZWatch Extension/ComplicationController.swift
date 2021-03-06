//
//  ComplicationController.swift
//  ANZWatch Extension
//
//  Created by Will Townsend on 7/02/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import ClockKit
import WatchKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    var balance: String {
        let delegate = WKExtension.shared().delegate as! ExtensionDelegate
        return delegate.balance
    }
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirections(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([])
    }
    
    func getTimelineStartDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.hideOnLockScreen)
    }
    
    func requestedUpdateDidBegin() {
        
        print("Requested update")
        
        let delegate = WKExtension.shared().delegate as! ExtensionDelegate
        
        print("Fetching balances")
        delegate.requestBalances { (_) in
            
            print("Reloading complications")
            
            let complicationServer = CLKComplicationServer.sharedInstance()
            
            guard let activeComplications = complicationServer.activeComplications else {
                return
            }
            
            for complication in activeComplications {
                complicationServer.reloadTimeline(for: complication)
            }
        }
        
    }
    
    func getNextRequestedUpdateDate(handler: @escaping (Date?) -> Void) {
        handler(Date(timeIntervalSinceNow: 60 * 2))
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Call the handler with the current timeline entry
        
        switch complication.family {
        case .utilitarianLarge:
            
            let template = CLKComplicationTemplateUtilitarianLargeFlat()
            template.textProvider = CLKSimpleTextProvider(text: self.balance)
            
            let timelineEntry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
            
            handler(timelineEntry)
            
        default:
            handler(nil)
        }
        
    }
    
    func getTimelineEntries(for complication: CLKComplication, before date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries prior to the given date
        handler(nil)
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after to the given date
        handler(nil)
    }
    
    // MARK: - Placeholder Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        
        switch complication.family {
        case .utilitarianLarge:
            
            let template = CLKComplicationTemplateUtilitarianLargeFlat()
            template.textProvider = CLKSimpleTextProvider(text: "Loading...")
            handler(template)
            
        default:
            handler(nil)
        }
        
        // This method will be called once per supported complication, and the results will be cached
        handler(nil)
    }
    
}


