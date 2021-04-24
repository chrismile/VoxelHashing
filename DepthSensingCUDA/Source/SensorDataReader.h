#pragma once


/************************************************************************/
/* Reads sensor data files from .sens files                            */
/************************************************************************/

#include "GlobalAppState.h"
#include "RGBDSensor.h"
#include "stdafx.h"

#ifdef SENSOR_DATA_READER

namespace ml {
	class SensorData;
	class RGBDFrameCacheRead;
}

class FrameQueue;
class FrameCache;

class SensorDataReader : public RGBDSensor
{
public:
	//! Constructor
	SensorDataReader();

	//! Destructor; releases allocated ressources
	~SensorDataReader();

	//! initializes the sensor
	HRESULT createFirstConnected();

	//! reads the next depth frame
	HRESULT processDepth();


	HRESULT processColor()	{
		//everything done in process depth since order is relevant (color must be read first)
		return S_OK;
	}

	std::string getSensorName() const;

	mat4f getRigidTransform(int offset) const;

	virtual float getDepthShift() const override;

	const SensorData* getSensorData() const {
		return m_sensorData;
	}

	unsigned int getNumFrames() const {
		return m_numFrames;
	}
	unsigned int getCurrFrame() const {
		return m_currFrame;
	}
	unsigned int getCurrSensFileIdx() const {
		return m_currSensFileIdx;
	}

	void setCurrFrame(unsigned int currFrame);
	void loadNextSensFile();
private:
	//! deletes all allocated data
	void releaseData();

	ml::SensorData* m_sensorData;
	ml::RGBDFrameCacheRead* m_sensorDataCache;
	FrameQueue*     m_frameQueue = nullptr; ///< if GlobalAppState::get().s_useTemporalReconstruction && !GlobalAppState::get().s_processSubset
	unsigned int    m_queueStartIdx = 0; ///< if GlobalAppState::get().s_useTemporalReconstruction && !GlobalAppState::get().s_processSubset
	FrameCache*     m_frameCache = nullptr; ///< if GlobalAppState::get().s_processSubset
	unsigned int	m_sensorDataCacheCurrFrame = 0; ///< if GlobalAppState::get().s_processSubset

	unsigned int	m_numFrames;
	unsigned int	m_currFrame;
	bool			m_bHasColorData;

	unsigned int	m_currSensFileIdx;

};


#endif	//sensor data reader
