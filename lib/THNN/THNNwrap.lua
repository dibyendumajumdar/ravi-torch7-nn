local wrap = require 'cwrap'

local interface = wrap.CInterface.new()
local argtypes = wrap.CInterface.argtypes

argtypes['ptrdiff_t'] = wrap.types.ptrdiff_t

argtypes.THNNState = {

   helpname = function(arg)
                 return "THNNState *"
              end,

   declare = function(arg)
                -- if it is a number we initialize here
                return string.format("THNNState *arg%d = NULL;", arg.i)
             end,

   check = function(arg, idx)
              return string.format("1", idx)
           end,

   read = function(arg, idx)
             return string.format("arg%d = NULL;", arg.i)
          end,

   init = function(arg)
             -- otherwise do it here
             return string.format("arg%d = NULL;", arg.i)
          end,

   carg = function(arg)
             return string.format('arg%d', arg.i)
          end,

   creturn = function(arg)
                return string.format('arg%d', arg.i)
             end,

   precall = function(arg)
                if arg.returned then
                   return string.format('lua_pushnil(L);')
                end
             end,

   postcall = function(arg)
                 if arg.creturned then
                    return string.format('lua_pushnil(L);')
                 end
              end
}

interface:print([[
#ifdef __cplusplus
#define THNN_EXTERNC extern "C"
#else
#define THNN_EXTERNC extern
#endif

#ifdef _WIN32
#ifdef THNN_EXPORTS
#define THNN_API THNN_EXTERNC __declspec(dllexport)
#else
#define THNN_API THNN_EXTERNC __declspec(dllimport)
#endif
#else
#define THNN_API THNN_EXTERNC
#endif

#ifdef __cplusplus
extern "C" {
#endif
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>

THNN_API int luaopen_THNN(lua_State *L);

#ifdef __cplusplus
}
#endif

#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#include "TH.h"
#include "THMath.h"
#include "THNN.h"
#include "luaT.h"
]])

-- specific to torch: we generate a 'dispatch' function
-- first we create a helper function
-- note that it let the "torch" table on the stack
interface:print([[
static const void* torch_istensortype(lua_State *L, const char *tname)
{
  if(!tname)
    return NULL;

  if(!luaT_pushmetatable(L, tname))
    return NULL;

  lua_pushstring(L, "torch");
  lua_rawget(L, -2);
  if(lua_istable(L, -1))
    return tname;
  else
  {
    lua_pop(L, 2);
    return NULL;
  }

  return NULL;
}
]])

interface:print([[
static int torch_isnonemptytable(lua_State *L, int idx)
{
  int empty;
  if (!lua_istable(L, idx)) return 0;

  lua_rawgeti(L, idx, 1);
  empty = lua_isnil(L, -1);
  lua_pop(L, 1);
  return !empty;
}
]])


interface:print([[
static const void* torch_istensorarray(lua_State *L, int idx)
{
  const char* tname;
  int tensor_idx;
  if (!torch_isnonemptytable(L, idx)) return 0;

  lua_checkstack(L, 3);
  lua_rawgeti(L, idx, 1);
  tensor_idx = lua_gettop(L);
  tname = (torch_istensortype(L, luaT_typename(L, -1)));
  lua_remove(L, tensor_idx);
  return tname;
}
]])

interface:print('/* WARNING: autogenerated file */')
interface:print('')

local function wrap(...)
   local args = {...}
   -- interface
   interface:wrap(...)
end

local reals = {ByteTensor='uint8_t',
               CharTensor='int8_t',
               ShortTensor='int16_t',
               IntTensor='int32_t',
               LongTensor='int64_t',
               FloatTensor='float',
               HalfTensor='half',
               DoubleTensor='double'}

local accreals = {ByteTensor='int64_t',
               CharTensor='int64_t',
               ShortTensor='int64_t',
               IntTensor='int64_t',
               LongTensor='int64_t',
               FloatTensor='double',
               HalfTensor='float',
               DoubleTensor='double'}

for _,Tensor in ipairs({"FloatTensor", "DoubleTensor"}) do

   local real = reals[Tensor]
   local accreal = accreals[Tensor]
   local prefix = Tensor == "FloatTensor" and "Float" or "Double"

   function interface.luaname2wrapname(self, name)
      return string.format('torch_%s_%s', prefix, name)
   end

   local function cname(name)      
      return string.format('THNN_%s%s', prefix, name)
   end

   local function lastdim(argn)
      return function(arg)
                return string.format("TH%s_nDimension(%s)", Tensor, arg.args[argn]:carg())
             end
   end

   local function lastdimarray(argn)
      return function(arg)
                return string.format("TH%s_nDimension(arg%d_data[0])", Tensor, arg.args[argn].i)
             end
   end

   local THNNState = "THNNState"

   if Tensor == 'FloatTensor' or Tensor == 'DoubleTensor' then

      wrap("Abs_updateOutput",
           cname("Abs_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor}})
      wrap("Abs_updateGradInput",
           cname("Abs_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor}})

      wrap("AbsCriterion_updateOutput",
           cname("AbsCriterion_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name='boolean'}})
      wrap("AbsCriterion_updateGradInput",
           cname("AbsCriterion_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name='boolean'}})

      wrap("BCECriterion_updateOutput",
           cname("BCECriterion_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name='boolean'},
            {name=Tensor}})
      wrap("BCECriterion_updateGradInput",
           cname("BCECriterion_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name='boolean'},
            {name=Tensor}})

      wrap("ClassNLLCriterion_updateOutput",
           cname("ClassNLLCriterion_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name='IndexTensor'},
            {name=Tensor},
            {name='boolean'},
            {name=Tensor},
            {name=Tensor},
            {name='int64_t'}})
      wrap("ClassNLLCriterion_updateGradInput",
           cname("ClassNLLCriterion_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name='IndexTensor'},
            {name=Tensor},
            {name='boolean'},
            {name=Tensor},
            {name=Tensor},
            {name='int64_t'}})

      wrap("SpatialClassNLLCriterion_updateOutput",
           cname("SpatialClassNLLCriterion_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name='IndexTensor'},
            {name=Tensor},
            {name='boolean'},
            {name=Tensor},
            {name=Tensor}})
      wrap("SpatialClassNLLCriterion_updateGradInput",
           cname("SpatialClassNLLCriterion_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name='IndexTensor'},
            {name=Tensor},
            {name='boolean'},
            {name=Tensor},
            {name=Tensor}})

      wrap("ELU_updateOutput",
           cname("ELU_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=accreal},
            {name='boolean'}})
      wrap("ELU_updateGradInput",
           cname("ELU_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},            
            {name=Tensor},            
            {name=accreal},
            {name='boolean'}})

      wrap("DistKLDivCriterion_updateOutput",
           cname("DistKLDivCriterion_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name='boolean'}})
      wrap("DistKLDivCriterion_updateGradInput",
           cname("DistKLDivCriterion_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name='boolean'}})

      wrap("GatedLinear_updateOutput",
           cname("GatedLinear_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name='int'}})
      wrap("GatedLinear_updateGradInput",
           cname("GatedLinear_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name='int'}})

      wrap("HardShrink_updateOutput",
           cname("HardShrink_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=accreal}})
      wrap("HardShrink_updateGradInput",
           cname("HardShrink_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=accreal}})

      wrap("HardTanh_updateOutput",
           cname("HardTanh_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=accreal},
            {name=accreal},
            {name='boolean'}})
      wrap("HardTanh_updateGradInput",
           cname("HardTanh_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=accreal},
            {name=accreal},
            {name='boolean'}})

      wrap("L1Cost_updateOutput",
           cname("L1Cost_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor}})
      wrap("L1Cost_updateGradInput",
           cname("L1Cost_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor}})

      wrap("LeakyReLU_updateOutput",
           cname("LeakyReLU_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=accreal},
            {name='boolean'}})
      wrap("LeakyReLU_updateGradInput",
           cname("LeakyReLU_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},            
            {name=accreal},
            {name='boolean'}})

      wrap("GRUFused_updateOutput",
           cname("GRUFused_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},            
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor}})
      wrap("GRUFused_updateGradInput",
           cname("GRUFused_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor}})

      wrap("LSTMFused_updateOutput",
           cname("LSTMFused_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},            
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor}})
      wrap("LSTMFused_updateGradInput",
           cname("LSTMFused_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},            
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor}})

      wrap("LogSigmoid_updateOutput",
           cname("LogSigmoid_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor}})
      wrap("LogSigmoid_updateGradInput",
           cname("LogSigmoid_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},            
            {name=Tensor}})

      wrap("LogSoftMax_updateOutput",
           cname("LogSoftMax_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor}})
      wrap("LogSoftMax_updateGradInput",
           cname("LogSoftMax_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},            
            {name=Tensor}})

      wrap("LookupTable_accGradParameters",
           cname("LookupTable_accGradParameters"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name='IndexTensor'},
            {name=Tensor},
            {name=Tensor},
            {name='IntTensor'},            
            {name=Tensor},
            {name='IndexTensor'},
            {name='boolean'},
            {name='int'},
            {name=accreal}})

      wrap("LookupTable_renorm",
           cname("LookupTable_renorm"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name='IndexTensor'},
            {name=Tensor},
            {name=accreal},
            {name=accreal}})

      wrap("MarginCriterion_updateOutput",
           cname("MarginCriterion_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name='boolean'},
            {name=accreal}})
      wrap("MarginCriterion_updateGradInput",
           cname("MarginCriterion_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name='boolean'},
            {name=accreal}})

      wrap("SoftMarginCriterion_updateOutput",
           cname("SoftMarginCriterion_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name='boolean'}})
      wrap("SoftMarginCriterion_updateGradInput",
           cname("SoftMarginCriterion_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name='boolean'}})

      wrap("MSECriterion_updateOutput",
           cname("MSECriterion_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name='boolean'}})
      wrap("MSECriterion_updateGradInput",
           cname("MSECriterion_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name='boolean'}})

      wrap("MultiLabelMarginCriterion_updateOutput",
           cname("MultiLabelMarginCriterion_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name='IndexTensor'},
            {name=Tensor},
            {name=Tensor},
            {name='boolean'}})
      wrap("MultiLabelMarginCriterion_updateGradInput",
           cname("MultiLabelMarginCriterion_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name='IndexTensor'},
            {name=Tensor},
            {name=Tensor},
            {name='boolean'}})

      wrap("MultiMarginCriterion_updateOutput",
           cname("MultiMarginCriterion_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name='IndexTensor'},
            {name=Tensor},
            {name='boolean'},
            {name='int'},
            {name=Tensor},
            {name=accreal}})
      wrap("MultiMarginCriterion_updateGradInput",
           cname("MultiMarginCriterion_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name='IndexTensor'},
            {name=Tensor},
            {name='boolean'},
            {name='int'},
            {name=Tensor},
            {name=accreal}})

      wrap("PReLU_updateOutput",
           cname("PReLU_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name='index'}})
      wrap("PReLU_updateGradInput",
           cname("PReLU_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name='index'}})
      wrap("PReLU_accGradParameters",
           cname("PReLU_accGradParameters"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name='index'},
            {name=accreal}})

      wrap("Linear_updateOutput",
           cname("Linear_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor}})
      wrap("Linear_updateGradInput",
           cname("Linear_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor}})
      wrap("Linear_accGradParameters",
           cname("Linear_accGradParameters"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=accreal}})

      wrap("RReLU_updateOutput",
           cname("RReLU_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=accreal},
            {name=accreal},
            {name='boolean'},
            {name='boolean'},
            {name='Generator'}})
      wrap("RReLU_updateGradInput",
           cname("RReLU_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=accreal},
            {name=accreal},
            {name='boolean'},
            {name='boolean'}})

      wrap("Sigmoid_updateOutput",
           cname("Sigmoid_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor}})
      wrap("Sigmoid_updateGradInput",
           cname("Sigmoid_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor}})

      wrap("SmoothL1Criterion_updateOutput",
           cname("SmoothL1Criterion_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name='boolean'}})
      wrap("SmoothL1Criterion_updateGradInput",
           cname("SmoothL1Criterion_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name='boolean'}})

      wrap("SoftMax_updateOutput",
           cname("SoftMax_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor}})
      wrap("SoftMax_updateGradInput",
           cname("SoftMax_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor}})

      wrap("SoftPlus_updateOutput",
           cname("SoftPlus_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=accreal},
            {name=accreal}})
      wrap("SoftPlus_updateGradInput",
           cname("SoftPlus_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=accreal},
            {name=accreal}}) 

      wrap("SoftShrink_updateOutput",
           cname("SoftShrink_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=accreal}})
      wrap("SoftShrink_updateGradInput",
           cname("SoftShrink_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=accreal}})            

      wrap("IndexLinear_updateOutput",
           cname("IndexLinear_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name='IndexTensor'},
            {name='int64_t'},
            {name=Tensor},
            {name='IndexTensor'},
            {name='IndexTensor'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name='int'}})
      wrap("IndexLinear_accGradParameters",
           cname("IndexLinear_accGradParameters"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name='IndexTensor'},
            {name='int64_t'},
            {name=Tensor},
            {name='IndexTensor'},
            {name='IndexTensor'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=accreal},
            {name=accreal}})
      wrap("IndexLinear_accUpdateGradParameters",
           cname("IndexLinear_accUpdateGradParameters"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name='IndexTensor'},
            {name='int64_t'},
            {name=Tensor},
            {name='IndexTensor'},
            {name='IndexTensor'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=accreal},
            {name=accreal}})
      wrap("IndexLinear_updateParameters",
           cname("IndexLinear_updateParameters"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name='IndexTensor'},
            {name='IndexTensor'},
            {name='int64_t'},
            {name=accreal},
            {name=accreal}})

      wrap("SparseLinear_updateOutput",
           cname("SparseLinear_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor}})
      wrap("SparseLinear_accGradParameters",
           cname("SparseLinear_accGradParameters"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=accreal},
            {name=accreal}})
      wrap("SparseLinear_zeroGradParameters",
           cname("SparseLinear_zeroGradParameters"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor}})
      wrap("SparseLinear_updateParameters",
           cname("SparseLinear_updateParameters"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=accreal}})
      wrap("SparseLinear_legacyUpdateOutput",
           cname("SparseLinear_legacyUpdateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor}})
      wrap("SparseLinear_legacyAccGradParameters",
           cname("SparseLinear_legacyAccGradParameters"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=accreal},
            {name=accreal}})
      wrap("SparseLinear_legacyZeroGradParameters",
           cname("SparseLinear_legacyZeroGradParameters"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor}})
      wrap("SparseLinear_legacyUpdateParameters",
           cname("SparseLinear_legacyUpdateParameters"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=accreal}})

      wrap("Sqrt_updateOutput",
           cname("Sqrt_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=accreal}})
      wrap("Sqrt_updateGradInput",
           cname("Sqrt_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor}})

      wrap("Square_updateOutput",
           cname("Square_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor}})
      wrap("Square_updateGradInput",
           cname("Square_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor}})

      wrap("Tanh_updateOutput",
           cname("Tanh_updateOutput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor}})
      wrap("Tanh_updateGradInput",
           cname("Tanh_updateGradInput"),
           {{name=THNNState, invisible=true, default='NULL'},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor},
            {name=Tensor}})

   end
   interface:register(string.format("torch_%sTHNN__", Tensor))

   interface:print(string.gsub([[
static void torch_TensorTHNN_init(lua_State *L)
{
  if (!luaT_pushmetatable(L, "torch.Tensor"))
    return;

  /* register functions into the "THNN" field of the tensor metaclass */
  lua_pushstring(L, "THNN");
  lua_newtable(L);
  luaT_setfuncs(L, torch_TensorTHNN__, 0);
  lua_rawset(L, -3);
  lua_pop(L, 1);

}
]], 'Tensor', Tensor))
end

interface:print([[
int luaopen_THNN(lua_State *L) {
  fprintf(stderr, "Initializing THNN\n");
  torch_FloatTensorTHNN_init(L);
  torch_DoubleTensorTHNN_init(L);
  lua_createtable(L, 0, 0);
  fprintf(stdout, "THNN initialized successfully\n");
  return 1;
}
]])

if arg[1] then
   interface:tofile(arg[1])
else
   print(interface:tostring())
end