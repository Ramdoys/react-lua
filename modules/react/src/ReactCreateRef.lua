-- upstream: https://github.com/facebook/react/blob/b87aabdfe1b7461e7331abb3601d9e6bb27544bc/packages/react/src/ReactCreateRef.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 * @flow
*]]

local Packages = script.Parent.Parent
-- FIXME: Sharing type definitions across packages
local ReactTypes = require(Packages.Shared)
type RefObject = ReactTypes.RefObject

local exports = {}
-- an immutable object with a single mutable value
exports.createRef = function(): RefObject
  local refObject = {
    current = nil,
  }
  if _G.__DEV__ then
    -- ROBLOX FIXME: We can't do this, since `current` won't be recognized as a
    -- member if it's nil. We could do this using a sentinel value, but that
    -- would leak to user space. How should we address this?
    -- Object.seal(refObject)
  end
  return refObject
end

return exports
