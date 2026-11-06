function prv = ls_upqc_private()
%LS_UPQC_PRIVATE  Handles to the functions of ./private, for init_model.m.
%
%   prv = ls_upqc_private()   struct with one field per file of ./private: prv.<name> is a handle to <name>
%
%   The Live Editor runs a live script from a temporary copy outside this folder, so init_model.m cannot
%   call the functions of ./private directly. This function sits next to ./private: the handles it
%   creates point to the private functions and can be called from anywhere (prv.timing_param(...)).
%   Same file as mpc_psm_private.m in modelization-and-control.

    files = dir(fullfile(fileparts(mfilename('fullpath')), 'private', '*.m'));
    prv = struct();
    for k = 1:numel(files)
        [~, name] = fileparts(files(k).name);
        prv.(name) = eval(['@' name]);
    end
end
