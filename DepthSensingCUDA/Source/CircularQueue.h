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

#include "sensorData/sensorData.h"

#pragma once

class CircularQueue
{
public:
	CircularQueue(size_t maxCapacity = 32);
	~CircularQueue();

	void enqueue(const ml::RGBDFrameCacheRead::FrameState& data);
	ml::RGBDFrameCacheRead::FrameState popFront();
	ml::RGBDFrameCacheRead::FrameState at(size_t index);

	inline size_t isEmpty() { return queueSize == 0; }
	inline size_t getSize() { return queueSize; }
	inline size_t getCapacity() { return queueCapacity; }

	void resize(size_t newCapacity);

private:
	ml::RGBDFrameCacheRead::FrameState *queueData;
	size_t startPointer, endPointer;
	size_t queueCapacity;
	size_t queueSize;
};
