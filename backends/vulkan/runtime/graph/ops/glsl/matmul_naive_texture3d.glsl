/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

#version 450 core

#define PRECISION ${PRECISION}

$if MAT2_IS_TRANSPOSED:
  #define MAT2_IS_TRANSPOSED

#include "indexing_utils.h"
#include "matmul.h"

${layout_declare_tensor(0, "w", "im_out", DTYPE, "texture3d")}
${layout_declare_tensor(1, "r", "im_mat1", DTYPE, "texture3d")}
${layout_declare_tensor(2, "r", "im_mat2", DTYPE, "texture3d")}
${layout_declare_ubo(3, "ivec3", "out_limits")}
${layout_declare_ubo(4, "ivec4", "in_sizes")}

layout(local_size_x_id = 0, local_size_y_id = 1, local_size_z_id = 2) in;

void main() {
  const ivec3 pos = ivec3(gl_GlobalInvocationID);

  if (any(greaterThanEqual(pos, out_limits))) {
    return;
  }

  vec4 texel = vec4(0);

  $if MAT1_PACKING == "W_packed":
    $if MAT2_PACKING == "H_packed":
      texel = matmul_naive_W_packed_H_packed(
          im_mat1,
          im_mat2,
          pos,
          in_sizes[0]);
    $elif MAT2_PACKING == "W_packed":
      texel = matmul_naive_W_packed_W_packed(
          im_mat1,
          im_mat2,
          pos,
          in_sizes[0]);
    $else:
      $raise Exception("Unsupported value for MAT2_PACKING")
  $else:
    $raise Exception("Unsupported value combo for MAT1_PACKING and MAT2_PACKING")

  imageStore(im_out, pos, texel);
}
