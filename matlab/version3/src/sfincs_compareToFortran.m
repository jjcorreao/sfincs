function sfincs_compareToFortran(filename)

global Nspecies Ntheta Nzeta Nxi Nx NL collisionOperator includePhi1 RHSMode
global theta zeta x transportMatrix
global geometryScheme GHat IHat VPrimeHat FSABHat2 B0OverBBar iota BDotCurlB
global BHat dBHatdtheta dBHatdzeta dBHatdpsiHat
global DHat BHat_sub_psi BHat_sub_theta BHat_sub_zeta BHat_sup_theta BHat_sup_zeta
global dBHat_sub_psi_dtheta dBHat_sub_psi_dzeta
global dBHat_sub_theta_dpsiHat dBHat_sub_theta_dzeta
global dBHat_sub_zeta_dpsiHat dBHat_sub_zeta_dtheta
global dBHat_sup_theta_dpsiHat dBHat_sup_theta_dzeta
global dBHat_sup_zeta_dpsiHat dBHat_sup_zeta_dtheta
global psiHat psiN rHat rN

global FSADensityPerturbation FSABFlow FSAPressurePerturbation
global particleFlux_vm0_psiHat particleFlux_vm_psiHat particleFlux_vE0_psiHat particleFlux_vE_psiHat particleFlux_vd_psiHat particleFlux_vd1_psiHat
global momentumFlux_vm0_psiHat momentumFlux_vm_psiHat momentumFlux_vE0_psiHat momentumFlux_vE_psiHat momentumFlux_vd_psiHat momentumFlux_vd1_psiHat
global heatFlux_vm0_psiHat heatFlux_vm_psiHat heatFlux_vE0_psiHat heatFlux_vE_psiHat heatFlux_vd_psiHat heatFlux_vd1_psiHat heatFlux_withoutPhi1_psiHat
global jHat FSABjHat FSABjHatOverB0 FSABjHatOverRootFSAB2
global totalDensity totalPressure velocityUsingFSADensity velocityUsingTotalDensity MachUsingFSAThermalSpeed

%filename = 'sfincsOutput.h5';

succeeded = false;
try
    h5read(filename,'/BHat');
    succeeded = true;
catch
end

if ~succeeded
    % Try changing / to \ in filename, in case we are on a Windows
    % filesystem.
    originalFilename = filename;
    filename = strrep(filename,'/','\')
    try
        h5read(filename,'/BHat');
    catch
        fprintf('Unable to compare to fortran result: unable to open %s\n',originalFilename)
        return
    end
end


fprintf('Comparing matlab results to fortran results in %s\n',filename)

% First compare 'input' quantities that should agree to within roundoff
% error.

tolerance = 1e-12;
comparisonType = 1;
% 1 = max(abs(difference)) < tolerance
% 2 = max(abs(difference) ./ mean) < tolerance

compare('Nspecies')
compare('Ntheta')
compare('Nzeta')
compare('Nxi')
compare('Nx')
compare('NL')
compare('theta')
compare('zeta')
compare('x')
compare('psiHat')
compare('psiN')
compare('rHat')
compare('rN')
compare('collisionOperator')
compare('geometryScheme')
compare('GHat')
compare('IHat')
compare('B0OverBBar')
compare('VPrimeHat')
compare('FSABHat2')
compare('iota')
compare('BHat')
compare('DHat')
compare('BDotCurlB')
compare('dBHatdpsiHat')
compare('dBHatdtheta')
compare('dBHatdzeta')
compare('BHat_sub_psi')
compare('BHat_sub_theta')
compare('BHat_sub_zeta')
compare('BHat_sup_theta')
compare('BHat_sup_zeta')

compare('dBHat_sub_psi_dtheta')
compare('dBHat_sub_psi_dzeta')

compare('dBHat_sub_theta_dpsiHat')
compare('dBHat_sub_theta_dzeta')

compare('dBHat_sub_zeta_dtheta')
compare('dBHat_sub_zeta_dpsiHat')

%compare('dBHat_sup_theta_dpsiHat')
compare('dBHat_sup_theta_dzeta')

compare('dBHat_sup_zeta_dtheta')
%compare('dBHat_sup_zeta_dpsiHat')

% Now compare 'output' quantities that will differ beyond the solver
% tolerance.

tolerance = 0.003;
comparisonType = 2;

if RHSMode==1
    compare('FSABFlow')
    compare('FSABjHat')
    if Nspecies>1 || collisionOperator==1 || includePhi1
        % If using Fokker-Planck operator with 1 species, particle flux comes
        % out to be ~0, so don't try to compare it then.
        compare('particleFlux_vm_psiHat')
    end
    if includePhi1
        compare('particleFlux_vE_psiHat')
        compare('particleFlux_vE0_psiHat')
        if Nspecies>1 || collisionOperator==1
            compare('particleFlux_vd_psiHat')
            compare('particleFlux_vd1_psiHat')
        end
    end
    compare('heatFlux_vm_psiHat')
    if includePhi1
        compare('heatFlux_vE_psiHat')
        compare('heatFlux_vE0_psiHat')
        compare('heatFlux_vd_psiHat')
        compare('heatFlux_vd1_psiHat')
        compare('heatFlux_withoutPhi1_psiHat')
    end
else
    compare('transportMatrix')
end

    function compare(varName)
        matlabVar = eval(varName);
        try
            fortranVar = h5read(filename,['/',varName]);
        catch
            fprintf('** WARNING: Unable to test variable %s since it does not exist in %s\n',varName,filename)
            return
        end
        
        if isvector(matlabVar)
            % If we have a 1D vector, 
            matlabVar = matlabVar(:);
            fortranVar = fortranVar(:);
        end
        
        try
            difference = abs(matlabVar-fortranVar);
        catch
            fprintf('** ERROR! Matlab and fortran variables %s are different sizes.\n',varName)
            fprintf('Size of matlab version:\n')
            size(matlabVar)            
            fprintf('Size of fortran version:\n')
            size(fortranVar)
            return
        end
        
        switch comparisonType
            case 1
                scalarDifference = max(max(max(difference)));
            case 2
                avg = abs(matlabVar+fortranVar)/2;
                scalarDifference = max(max(max(difference./avg)));
            otherwise
                error('Invalid comparisonType')
        end
        
        if scalarDifference < tolerance
            if numel(matlabVar)==1
                fprintf('  %s agrees. Matlab = %g, Fortran = %g\n',varName,matlabVar,fortranVar)
            elseif numel(matlabVar)==2
                fprintf('  %s agrees. Matlab = %g %g, Fortran = %g %g\n',varName,matlabVar(1),matlabVar(2),fortranVar(1),fortranVar(2))
            else
                fprintf('  %s agrees.\n',varName)
            end
        else
            fprintf('** ERROR!  %s disagrees! scalarDifference = %g\n',varName, scalarDifference)
            if numel(matlabVar)==1
                fprintf('  Matlab version: %g,  Fortran version: %g\n',matlabVar, fortranVar)
            elseif numel(size(matlabVar)) <= 2 && numel(matlabVar)<100
                fprintf('Here comes matlab version:\n')
                matlabVar
                fprintf('Here comes fortran version:\n')
                fortranVar
            end
            assignin('base',[varName,'_matlab'],matlabVar)
            assignin('base',[varName,'_fortran'],fortranVar)
        end
    end

end