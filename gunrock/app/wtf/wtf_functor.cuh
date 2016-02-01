// ----------------------------------------------------------------
// Gunrock -- Fast and Efficient GPU Graph Library
// ----------------------------------------------------------------
// This source code is distributed under the terms of LICENSE.TXT
// in the root directory of this source distribution.
// ---------------------------------------------------------------- 
/**
 * @file
 * wtf_functor.cuh
 *
 * @brief Device functions for WTF problem.
 */

#pragma once

#include <gunrock/app/problem_base.cuh>
#include <gunrock/app/wtf/wtf_problem.cuh>

namespace gunrock {
namespace app {
namespace wtf {

/**
 * @brief Structure contains device functions in WTF graph traverse.
 *
 * @tparam VertexId            Type of signed integer to use as vertex id (e.g., uint32)
 * @tparam SizeT               Type of unsigned integer to use for array indexing. (e.g., uint32)
 * @tparam ProblemData         Problem data type which contains data slice for WTF problem
 *
 */
template<typename VertexId, typename SizeT, typename Value, typename ProblemData>
struct PRFunctor
{
    typedef typename ProblemData::DataSlice DataSlice;

    /**
     * @brief Forward Edge Mapping condition function. Check if the destination node
     * has been claimed as someone else's child.
     *
     * @param[in] s_id Vertex Id of the edge source node
     * @param[in] d_id Vertex Id of the edge destination node
     * @param[in] problem Data slice object
     * @param[in] e_id Output edge id
     * @param[in] e_id_in Input edge id
     *
     * \return Whether to load the apply function for the edge and include the destination node in the next frontier.
     */
    static __device__ __forceinline__ bool CondEdge(VertexId s_id, VertexId d_id, DataSlice *problem, VertexId e_id = 0, VertexId e_id_in = 0)
    {
        return (problem->out_degrees[d_id] > 0 && problem->out_degrees[s_id] > 0);
    }

    /**
     * @brief Forward Edge Mapping apply function. Now we know the source node
     * has succeeded in claiming child, so it is safe to set label to its child
     * node (destination node).
     *
     * @param[in] s_id Vertex Id of the edge source node
     * @param[in] d_id Vertex Id of the edge destination node
     * @param[in] problem Data slice object
     * @param[in] e_id Output edge id
     * @param[in] e_id_in Input edge id
     *
     */
    static __device__ __forceinline__ void ApplyEdge(VertexId s_id, VertexId d_id, DataSlice *problem, VertexId e_id = 0, VertexId e_id_in = 0)
    {
        atomicAdd(&problem->rank_next[d_id], problem->rank_curr[s_id]/problem->out_degrees[s_id]);
    }

    /**
     * @brief Vertex mapping condition function. Check if the Vertex Id is valid (not equal to -1).
     *
     * @param[in] node Vertex Id
     * @param[in] problem Data slice object
     * @param[in] v Value
     * @param[in] nid Node ID
     *
     * \return Whether to load the apply function for the node and include it in the outgoing vertex frontier.
     */
    static __device__ __forceinline__ bool CondFilter(VertexId node, DataSlice *problem, Value v = 0, SizeT nid=0)
    {
        Value delta = problem->delta;
        VertexId src_node = problem->src_node;
        Value threshold = (Value)problem->threshold;
        problem->rank_next[node] = (delta * problem->rank_next[node]) + (1.0-delta) * ((src_node == node || src_node == -1) ? 1 : 0);
        Value diff = fabs(problem->rank_next[node] - problem->rank_curr[node]);
 
        return (diff > threshold);
    }

    /**
     * @brief Vertex mapping apply function. Doing nothing for WTF problem.
     *
     * @param[in] node Vertex Id
     * @param[in] problem Data slice object
     * @param[in] v Value
     * @param[in] nid Node ID
     *
     */
    static __device__ __forceinline__ void ApplyFilter(VertexId node, DataSlice *problem, Value v = 0, SizeT nid=0)
    {
        // Doing nothing here
    }
};

/**
 * @brief Structure contains device functions in WTF graph traverse.
 *
 * @tparam VertexId            Type of signed integer to use as vertex id (e.g., uint32)
 * @tparam SizeT               Type of unsigned integer to use for array indexing. (e.g., uint32)
 * @tparam ProblemData         Problem data type which contains data slice for WTF problem
 *
 */
template<typename VertexId, typename SizeT, typename Value, typename ProblemData>
struct COTFunctor
{
    typedef typename ProblemData::DataSlice DataSlice;

    /**
     * @brief Forward Edge Mapping condition function. Check if the destination node
     * has been claimed as someone else's child.
     *
     * @param[in] s_id Vertex Id of the edge source node
     * @param[in] d_id Vertex Id of the edge destination node
     * @param[in] problem Data slice object
     * @param[in] e_id Output edge id
     * @param[in] e_id_in Input edge id
     *
     * \return Whether to load the apply function for the edge and include the destination node in the next frontier.
     */
    static __device__ __forceinline__ bool CondEdge(VertexId s_id, VertexId d_id, DataSlice *problem, VertexId e_id = 0, VertexId e_id_in = 0)
    {
        return true;
    }

    /**
     * @brief Forward Edge Mapping apply function. Now we know the source node
     * has succeeded in claiming child, so it is safe to set label to its child
     * node (destination node).
     *
     * @param[in] s_id Vertex Id of the edge source node
     * @param[in] d_id Vertex Id of the edge destination node
     * @param[in] problem Data slice object
     * @param[in] e_id Output edge id
     * @param[in] e_id_in Input edge id
     *
     */
    static __device__ __forceinline__ void ApplyEdge(VertexId s_id, VertexId d_id, DataSlice *problem, VertexId e_id = 0, VertexId e_id_in = 0)
    {
        atomicAdd(&problem->in_degrees[d_id], 1);
    }
};

/**
 * @brief Structure contains device functions in HITS graph traverse.
 *
 * @tparam VertexId            Type of signed integer to use as vertex id (e.g., uint32)
 * @tparam SizeT               Type of unsigned integer to use for array indexing. (e.g., uint32)
 * @tparam ProblemData         Problem data type which contains data slice for HITS problem
 *
 */
template<typename VertexId, typename SizeT, typename Value, typename ProblemData>
struct HUBFunctor
{
    typedef typename ProblemData::DataSlice DataSlice;

    /**
     * @brief Forward Edge Mapping condition function. Check if the destination node
     * has been claimed as someone else's child.
     *
     * @param[in] s_id Vertex Id of the edge source node
     * @param[in] d_id Vertex Id of the edge destination node
     * @param[in] problem Data slice object
     * @param[in] e_id Output edge id
     * @param[in] e_id_in Input edge id
     *
     * \return Whether to load the apply function for the edge and include the destination node in the next frontier.
     */
    static __device__ __forceinline__ bool CondEdge(VertexId s_id, VertexId d_id, DataSlice *problem, VertexId e_id = 0, VertexId e_id_in = 0)
    {
        return true;
    }

    /**
     * @brief Forward Edge Mapping apply function. Now we know the source node
     * has succeeded in claiming child, so it is safe to set label to its child
     * node (destination node).
     *
     * @param[in] s_id Vertex Id of the edge source node
     * @param[in] d_id Vertex Id of the edge destination node
     * @param[in] problem Data slice object
     * @param[in] e_id Output edge id
     * @param[in] e_id_in Input edge id
     *
     */
    static __device__ __forceinline__ void ApplyEdge(VertexId s_id, VertexId d_id, DataSlice *problem, VertexId e_id = 0, VertexId e_id_in = 0)
    {
        Value val = (s_id == problem->src_node ? problem->alpha/problem->out_degrees[s_id] : 0)
                  + (1-problem->alpha)*problem->refscore_curr[d_id]/problem->in_degrees[d_id];
        atomicAdd(&problem->rank_next[s_id], val);
    }

};

/**
 * @brief Structure contains device functions in HITS graph traverse.
 *
 * @tparam VertexId            Type of signed integer to use as vertex id (e.g., uint32)
 * @tparam SizeT               Type of unsigned integer to use for array indexing. (e.g., uint32)
 * @tparam ProblemData         Problem data type which contains data slice for HITS problem
 *
 */
template<typename VertexId, typename SizeT, typename Value, typename ProblemData>
struct AUTHFunctor
{
    typedef typename ProblemData::DataSlice DataSlice;

    /**
     * @brief Forward Edge Mapping condition function. Check if the destination node
     * has been claimed as someone else's child.
     *
     * @param[in] s_id Vertex Id of the edge source node
     * @param[in] d_id Vertex Id of the edge destination node
     * @param[in] problem Data slice object
     * @param[in] e_id Output edge id
     * @param[in] e_id_in Input edge id
     *
     * \return Whether to load the apply function for the edge and include the destination node in the next frontier.
     */
    static __device__ __forceinline__ bool CondEdge(VertexId s_id, VertexId d_id, DataSlice *problem, VertexId e_id = 0, VertexId e_id_in = 0)
    {
        return true;
    }

    /**
     * @brief Forward Edge Mapping apply function. Now we know the source node
     * has succeeded in claiming child, so it is safe to set label to its child
     * node (destination node).
     *
     * @param[in] s_id Vertex Id of the edge source node
     * @param[in] d_id Vertex Id of the edge destination node
     * @param[in] problem Data slice object
     * @param[in] e_id Output edge id
     * @param[in] e_id_in Input edge id
     *
     */
    static __device__ __forceinline__ void ApplyEdge(VertexId s_id, VertexId d_id, DataSlice *problem, VertexId e_id = 0, VertexId e_id_in = 0)
    {
        Value val = problem->rank_curr[s_id]/ (problem->out_degrees[s_id] > 0 ? problem->out_degrees[s_id] : 1.0);
        atomicAdd(&problem->refscore_next[d_id], val);
    }
};

} // wtf
} // app
} // gunrock

// Leave this at the end of the file
// Local Variables:
// mode:c++
// c-file-style: "NVIDIA"
// End:
