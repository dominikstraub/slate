//
//  CarbonCompat.h
//  Slate
//
//  Created by Dominik Straub in 2026.
//  Copyright 2026 Dominik Straub. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see http://www.gnu.org/licenses
//
//  Wrapper to suppress Carbon deprecation warnings.
//  Carbon hotkey APIs (RegisterEventHotKey, etc.) are deprecated but still
//  functional on Apple Silicon. This header silences the warnings until
//  a full migration to a modern hotkey API is done.

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#import <Carbon/Carbon.h>
#pragma clang diagnostic pop
