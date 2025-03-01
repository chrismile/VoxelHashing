#include "stdafx.h"

#include "VoxelUtilHashSDF.h"

#include "Util.h"

#include "CUDARayCastSDF.h"
#include "CUDAHoleFiller.h"


extern "C" void renderCS(
	const HashData& hashData,
	const RayCastData &rayCastData, 
	const DepthCameraData &cameraData,
	const RayCastParams &rayCastParams);

extern "C" void computeNormals(float4* d_output, float4* d_input, unsigned int width, unsigned int height);
extern "C" void computeDepth4(float4* d_depth4, float* d_depth, const DepthCameraData& cameraData, unsigned int width, unsigned int height);
extern "C" void computeDepthMask(uint8_t* d_depthMask, float* d_depth, float4* d_depth4, float4* d_normals, unsigned int width, unsigned int height);
extern "C" void convertDepthFloatToCameraSpaceFloat4(float4* d_output, float* d_input, float4x4 intrinsicsInv, unsigned int width, unsigned int height, const DepthCameraData& depthCameraData);

extern "C" void resetRayIntervalSplatCUDA(RayCastData& data, const RayCastParams& params);
extern "C" void rayIntervalSplatCUDA(const HashData& hashData, const DepthCameraData& cameraData,
								 const RayCastData &rayCastData, const RayCastParams &rayCastParams);

Timer CUDARayCastSDF::m_timer;

void CUDARayCastSDF::create(const RayCastParams& params)
{
	m_params = params;
	m_data.allocate(m_params);
	m_rayIntervalSplatting.OnD3D11CreateDevice(DXUTGetD3D11Device(), params.m_width, params.m_height);
}

void CUDARayCastSDF::destroy(void)
{
	m_data.free();
	m_rayIntervalSplatting.OnD3D11DestroyDevice();
}

void CUDARayCastSDF::render(const HashData& hashData, const HashParams& hashParams, const DepthCameraData& cameraData, const mat4f& lastRigidTransform)
{
	rayIntervalSplatting(hashData, hashParams, cameraData, lastRigidTransform);
	m_data.d_rayIntervalSplatMinArray = m_rayIntervalSplatting.mapMinToCuda();
	m_data.d_rayIntervalSplatMaxArray = m_rayIntervalSplatting.mapMaxToCuda();

	// Start query for timing
	if(GlobalAppState::getInstance().s_timingsDetailledEnabled)
	{
		cutilSafeCall(cudaDeviceSynchronize()); 
		m_timer.start();
	}

	renderCS(hashData, m_data, cameraData, m_params);

	//convertToCameraSpace(cameraData);
	if (!m_params.m_useGradients)
	{
		if (GlobalAppState::getInstance().s_useDepthMapInpainting)
		{
			CUDAHoleFiller holeFiller;
			MLIB_CUDA_SAFE_CALL(cudaMemcpy(m_data.d_depthInpainted, m_data.d_depth, sizeof(float) * m_params.m_width * m_params.m_height, cudaMemcpyDeviceToDevice));
			holeFiller.holeFill(m_data.d_depthInpainted, m_params.m_width, m_params.m_height);
			//inpaintingDepthMap(m_data.d_depthInpainted, m_data.d_depth4Inpainted, m_data.d_depth4, m_params.m_width, m_params.m_height);
			computeDepth4(m_data.d_depth4Inpainted, m_data.d_depthInpainted, cameraData, m_params.m_width, m_params.m_height);

			computeNormals(m_data.d_normals, m_data.d_depth4, m_params.m_width, m_params.m_height);
			computeNormals(m_data.d_normalsInpainted, m_data.d_depth4Inpainted, m_params.m_width, m_params.m_height);
			computeDepthMask(m_data.d_depthMask, m_data.d_depth, m_data.d_depth4, m_data.d_normalsInpainted, m_params.m_width, m_params.m_height);
		}
		else
		{
			computeNormals(m_data.d_normals, m_data.d_depth4, m_params.m_width, m_params.m_height);
			computeDepthMask(m_data.d_depthMask, m_data.d_depth, m_data.d_depth4, m_data.d_normals, m_params.m_width, m_params.m_height);
		}
	}

	m_rayIntervalSplatting.unmapCuda();

	// Wait for query
	if(GlobalAppState::getInstance().s_timingsDetailledEnabled)
	{
		cutilSafeCall(cudaDeviceSynchronize()); 
		m_timer.stop();
		TimingLog::totalTimeRayCast+=m_timer.getElapsedTimeMS();
		TimingLog::countTimeRayCast++;
	}
}


void CUDARayCastSDF::convertToCameraSpace(const DepthCameraData& cameraData)
{
	convertDepthFloatToCameraSpaceFloat4(m_data.d_depth4, m_data.d_depth, m_params.m_intrinsicsInverse, m_params.m_width, m_params.m_height, cameraData);
	
	if(!m_params.m_useGradients) {
		computeNormals(m_data.d_normals, m_data.d_depth4, m_params.m_width, m_params.m_height);
	}
}

void CUDARayCastSDF::rayIntervalSplatting(const HashData& hashData, const HashParams& hashParams, const DepthCameraData& cameraData, const mat4f& lastRigidTransform)
{
	if (hashParams.m_numOccupiedBlocks == 0)	return;

	if (m_params.m_maxNumVertices <= 6*hashParams.m_numOccupiedBlocks) { // 6 verts (2 triangles) per block
		MLIB_EXCEPTION("not enough space for vertex buffer for ray interval splatting");
	}

	m_params.m_numOccupiedSDFBlocks = hashParams.m_numOccupiedBlocks;
	m_params.m_viewMatrix = MatrixConversion::toCUDA(lastRigidTransform.getInverse());
	m_params.m_viewMatrixInverse = MatrixConversion::toCUDA(lastRigidTransform);

	m_data.updateParams(m_params); // !!! debugging

	//don't use ray interval splatting (cf CUDARayCastSDF.cu -> line 40
	//m_rayIntervalSplatting.rayIntervalSplatting(DXUTGetD3D11DeviceContext(), hashData, cameraData, m_data, m_params, m_params.m_numOccupiedSDFBlocks*6);
}
