<?php

/**
 * PrescriptionRestController
 *
 * @package   OpenEMR
 * @link      http://www.open-emr.org
 * @author    Yash Bothra <yashrajbothra786gmail.com>
 * @copyright Copyright (c) 2020 Yash Bothra <yashrajbothra786gmail.com>
 * @license   https://github.com/openemr/openemr/blob/master/LICENSE GNU General Public License 3
 */

namespace OpenEMR\RestControllers;

use OpenEMR\Services\PrescriptionService;
use OpenEMR\RestControllers\RestControllerHelper;

class PrescriptionRestController
{
    private $prescriptionService;

    public function __construct()
    {
        $this->prescriptionService = new PrescriptionService();
    }

    /**
     * Process a HTTP POST request used to create a prescription record.
     * @param $data - array of prescription fields.
     * @return a 201/Created status code and the prescription identifier if successful.
     */
    public function post($data)
    {
        $processingResult = $this->prescriptionService->insert($data);
        return RestControllerHelper::handleProcessingResult($processingResult, 201);
    }

    /**
     * Fetches a single prescription resource by id.
     * @param $uuid- The prescription uuid identifier in string format.
     */
    public function getOne($uuid)
    {
        $processingResult = $this->prescriptionService->getOne($uuid);

        if (!$processingResult->hasErrors() && count($processingResult->getData()) == 0) {
            return RestControllerHelper::handleProcessingResult($processingResult, 404);
        }

        return RestControllerHelper::handleProcessingResult($processingResult, 200);
    }

    /**
     * Returns prescription resources which match an optional search criteria.
     */
    public function getAll($search = array())
    {
        $processingResult = $this->prescriptionService->getAll($search);
        return RestControllerHelper::handleProcessingResult($processingResult, 200, true);
    }

    public function delete($id)
    {
        $serviceResult = $this->prescriptionService->delete($id);
        return RestControllerHelper::responseHandler($serviceResult, null, 200);
    }
}
