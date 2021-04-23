/*
* BSD 2-Clause License
*
* Copyright (c) 2020, Christoph Neuhauser
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*
* * Redistributions of source code must retain the above copyright notice, this
*   list of conditions and the following disclaimer.
*
* * Redistributions in binary form must reproduce the above copyright notice,
*   this list of conditions and the following disclaimer in the documentation
*   and/or other materials provided with the distribution.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
* AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
* DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
* FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
* DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
* CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
* OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
* OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include "stdafx.h"

#include "FrameCache.h"

FrameCache::FrameCache(unsigned int numFrames, unsigned int capacity) : cache(capacity) {
	frameCacheIndexMap.resize(numFrames, std::numeric_limits<unsigned int>::max());
}

FrameCache::~FrameCache() {
	while (!cache.isEmpty()) {
		cache.popFront().second.free();
	}
}

bool FrameCache::isCached(unsigned int frameIdx) {
	return frameCacheIndexMap.at(frameIdx) != std::numeric_limits<unsigned int>::max();
}

ml::RGBDFrameCacheRead::FrameState FrameCache::getFromCache(unsigned int frameIdx) {
	assert(isCached(frameIdx));
	return cache.atAbsolute(frameCacheIndexMap.at(frameIdx)).second;
}

void FrameCache::storeInCache(unsigned int frameIdx, ml::RGBDFrameCacheRead::FrameState frameData) {
	// Space left in cache?
	if (cache.getSize() == cache.getCapacity()) {
		// Remove the oldest element.
		std::pair<unsigned int, ml::RGBDFrameCacheRead::FrameState> cachedData = cache.popFront();
		frameCacheIndexMap.at(cachedData.first) = std::numeric_limits<unsigned int>::max();
		cachedData.second.free();
	}
	frameCacheIndexMap.at(frameIdx) = static_cast<unsigned int>(cache.enqueueAbsolute(std::make_pair(frameIdx, frameData)));
}
