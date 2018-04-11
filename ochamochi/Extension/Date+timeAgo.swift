//
//  Date+ago.swift
//
//  A Swift port of ago function
//  Copyright (C) 2018 OSAMU SATO
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

extension Date {
    func ago() -> String {
        return self.timeAgo(false) + " ago"
    }
    
    func ago(short: Bool) -> String {
        return self.timeAgo(true)
    }
    
    private func timeAgo(_ short: Bool) -> String {
        let MINUTE_IN_SECONDS = 60.0
        let HOUR_IN_SECONDS = MINUTE_IN_SECONDS * 60.0
        let DAY_IN_SECONDS = HOUR_IN_SECONDS * 24.0
        let MONTH_IN_SECONDS = DAY_IN_SECONDS * 30.0
        let YEAR_IN_SECONDS = DAY_IN_SECONDS * 365.0
        
        let seconds = abs(NSDate().timeIntervalSince(self))
        var timeAgo = ""
        
        let year = Int(round(seconds / YEAR_IN_SECONDS))
        if (year > 0) {
            if (short) {
                timeAgo = "\(year)y"
            } else {
                timeAgo = "\(year) year"
                if (year > 1) {
                    timeAgo = timeAgo + "s"
                }
            }
            return timeAgo
        }
        
        let month = Int(round(seconds / MONTH_IN_SECONDS))
        if (month > 0) {
            if (short) {
                timeAgo = "\(month)m"
            } else {
                timeAgo = "\(month) month"
                if (month > 1) {
                    timeAgo = timeAgo + "s"
                }
            }
            return timeAgo
        }
        
        let day = Int(round(seconds / DAY_IN_SECONDS))
        if (day > 0) {
            if (short) {
                timeAgo = "\(day)d"
            } else {
                timeAgo = "\(day) day"
                if (day > 1) {
                    timeAgo = timeAgo + "s"
                }
            }
            return timeAgo
        }
        
        let hour = Int(round(seconds / HOUR_IN_SECONDS))
        if (hour > 0) {
            if (short) {
                timeAgo = "\(hour)h"
            } else {
                timeAgo = "\(hour) hour"
                if (hour > 1) {
                    timeAgo = timeAgo + "s"
                }
            }
            return timeAgo
        }
        
        let minute = Int(round(seconds / MINUTE_IN_SECONDS))
        if (minute > 0) {
            if (short) {
                timeAgo = "\(minute)m"
            } else {
                timeAgo = "\(minute) minute"
                if (minute > 1) {
                    timeAgo = timeAgo + "s"
                }
            }
            return timeAgo
        }
        
        let second = Int(round(seconds))
        if (short) {
            timeAgo = "\(second)s"
        } else {
            timeAgo = "\(second) second"
            if (second > 1) {
                timeAgo = timeAgo + "s"
            }
        }
        return timeAgo
    }
}
